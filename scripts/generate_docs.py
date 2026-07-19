import asyncio
import os
import re
import shlex
from pathlib import Path

from canonicalize_png import canonicalize
from pinned_openscad import openscad_path


OPENSCAD_PATTERN = re.compile(r"^\s*<!--\s*openscad (.+)\s*-->\s*$")
CONCURRENCY = asyncio.Semaphore(8)
CANONICALIZE_CONCURRENCY = asyncio.Semaphore(8)
OPENSCAD_ENVIRONMENT = os.environ | {
    "GALLIUM_DRIVER": "softpipe",
    "LIBGL_ALWAYS_SOFTWARE": "1",
    "MESA_LOADER_DRIVER_OVERRIDE": "softpipe",
}


async def render(command: list[str], output: str) -> None:
    output_path = Path(output)
    temporary_output = output_path.with_name(f".{output_path.name}.rendering.png")
    render_command = command.copy()
    render_command[render_command.index("-o") + 1] = str(temporary_output)
    max_attempts = 5
    try:
        for attempt in range(1, max_attempts + 1):
            async with CONCURRENCY:
                print("Running: " + shlex.join(command))
                process = await asyncio.create_subprocess_exec(
                    *render_command,
                    env=OPENSCAD_ENVIRONMENT,
                )
                await process.wait()
                if process.returncode != 0:
                    raise RuntimeError(
                        f"OpenSCAD exited with {process.returncode}: {shlex.join(command)}"
                    )
            if temporary_output.stat().st_size != 7763:
                async with CANONICALIZE_CONCURRENCY:
                    await asyncio.to_thread(canonicalize, temporary_output)
                os.replace(temporary_output, output_path)
                return
            print(
                f"Render failure for `{shlex.join(command)}` "
                f"({attempt}/{max_attempts}), retrying"
            )
        raise RuntimeError(
            f"Render failure after {max_attempts} attempts: {shlex.join(command)}"
        )
    finally:
        temporary_output.unlink(missing_ok=True)


async def render_group(commands: list[list[str]], output: str) -> None:
    # Some README examples intentionally use the same output for legacy and
    # renamed options. Run those sequentially so they cannot race over the
    # shared temporary and final paths.
    for command in commands:
        await render(command, output)


async def main() -> None:
    openscad = str(openscad_path())
    commands_by_output: dict[str, list[list[str]]] = {}
    with Path("README.md").open() as readme:
        for line in readme:
            match = OPENSCAD_PATTERN.match(line)
            if match:
                command = [
                    openscad,
                    "--enable",
                    "predictible-output",
                    "--hardwarnings",
                    "--projection=ortho",
                    "--colorscheme=Starnight",
                    "--render",
                    "--imgsize=2500,1000",
                    *shlex.split(match.group(1)),
                ]
                if not any(".scad" in argument for argument in command):
                    command.append("gridflock.scad")
                output = command[command.index("-o") + 1]
                commands_by_output.setdefault(output, []).append(command)

    for image in Path("docs/images").iterdir():
        if str(image) not in commands_by_output:
            image.unlink()
    await asyncio.gather(
        *(
            render_group(commands, output)
            for output, commands in commands_by_output.items()
        )
    )


if __name__ == "__main__":
    asyncio.run(main())
