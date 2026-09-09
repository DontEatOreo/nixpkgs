"""Update Creality Print's release and component pins in sources.json"""

import argparse
import difflib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


REPO = "CrealityOfficial/CrealityPrint"
PACKAGE = Path("pkgs/by-name/cr/creality-print")


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def api(endpoint):
    return json.loads(run("gh", "api", f"repos/{REPO}/{endpoint}"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", help="Release version; defaults to latest stable")
    parser.add_argument(
        "--check", action="store_true", help="Show changes without writing files"
    )
    parser.add_argument(
        "--checkout", type=Path, help="Reuse a clean checkout of the selected tag"
    )
    args = parser.parse_args()
    checkout = args.checkout.resolve() if args.checkout else None
    os.chdir(run("git", "rev-parse", "--show-toplevel"))
    path = PACKAGE / "sources.json"
    original = path.read_text()
    pins = json.loads(original)
    sources = json.loads(
        run(
            "nix-instantiate",
            "--eval",
            "--strict",
            "--json",
            "--expr",
            """
        let
          pkgs = import ./. { };
          sources = pkgs.lib.filterAttrs
            (_: value: builtins.isAttrs value && value ? src && value ? version)
            pkgs.creality-print.sources;
        in builtins.mapAttrs (_: value: {
          inherit (value.src) name sparseCheckout;
        }) sources
        """,
        )
    )
    endpoint = (
        f"releases/tags/v{args.version.removeprefix('v')}"
        if args.version
        else "releases/latest"
    )
    release = api(endpoint)
    tag = release["tag_name"]
    if (
        release["draft"]
        or release["prerelease"]
        or not re.fullmatch(r"v\d+\.\d+\.\d+", tag)
    ):
        raise RuntimeError(f"Expected a stable numeric release tag, got {tag}")
    version = tag[1:]
    # Match only this tag when releases contain assets for several versions
    asset_pattern = rf"CrealityPrint[-_]V?{re.escape(version)}\.(\d+)[-_]"
    builds = {
        match[1]
        for asset in release["assets"]
        if (match := re.match(asset_pattern, asset["name"], re.IGNORECASE))
    }
    if len(builds) != 1:
        raise RuntimeError(
            f"Expected one build number for {tag}, found {sorted(builds)}"
        )
    build_number = builds.pop()
    commit = api(f"commits/{tag}")
    revision = commit["sha"]
    date = commit["commit"]["committer"]["date"][:10]

    with tempfile.TemporaryDirectory(prefix="creality-print-update-") as directory:
        temporary = Path(directory)
        if checkout is None:
            checkout = temporary / "upstream"
            # gh honors the maintainer's configured Git transport and credentials
            subprocess.run(
                [
                    "gh",
                    "repo",
                    "clone",
                    REPO,
                    str(checkout),
                    "--",
                    "--depth=1",
                    "--single-branch",
                    "--branch",
                    tag,
                ],
                check=True,
            )
        if run("git", "-C", str(checkout), "rev-parse", "HEAD") != revision:
            raise RuntimeError(f"Checkout does not point to {tag} ({revision})")
        if run(
            "git", "-C", str(checkout), "status", "--porcelain", "--untracked-files=no"
        ):
            raise RuntimeError("Checkout has tracked changes")

        for name, source in sorted(sources.items()):
            print(f"Hashing {name} at {tag}", flush=True)
            # Fetch from the local clone once per selection, avoiding repeated
            # downloads with the exact sparse patterns from the package fetchers
            fetched = json.loads(
                run(
                    "nix-prefetch-git",
                    "--quiet",
                    "--url",
                    str(checkout),
                    "--rev",
                    revision,
                    "--name",
                    source["name"],
                    "--sparse-checkout",
                    "\n".join(source["sparseCheckout"]),
                    "--non-cone-mode",
                )
            )
            pin = pins["components"][name]
            if pin["hash"] != fetched["hash"] and "version" in pin:
                pin["version"] = f"unstable-{date}"
            pin["hash"] = fetched["hash"]

        pins["release"] = {
            "version": version,
            "buildNumber": build_number,
            "rev": revision,
        }

    # Fetching and validation finish before touching the working tree
    updated = json.dumps(pins, indent=2) + "\n"
    if path.read_text() != original:
        raise RuntimeError(f"{path} changed while the updater was running")
    changed = updated != original
    if changed:
        print(
            "".join(
                difflib.unified_diff(
                    original.splitlines(keepends=True),
                    updated.splitlines(keepends=True),
                    fromfile=str(path),
                    tofile=str(path),
                )
            ),
            end="",
        )
        if not args.check:
            path.write_text(updated)
    else:
        print(
            f"Creality Print {version}.{build_number} and all component hashes are current"
        )
    return int(args.check and bool(changed))


if __name__ == "__main__":
    raise SystemExit(main())
