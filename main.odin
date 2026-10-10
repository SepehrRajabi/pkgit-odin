package main

import "core:fmt"
import "core:os"

import "repository"

parse_file :: proc(file_path: string) -> ([]repository.Package, repository.File_Error) {
	packages, err := repository.parse_repo_file(file_path)
	if err != nil {
		return nil, err
	}
	return packages, nil
}

main :: proc() {
	if len(os.args) != 2 {
		fmt.println("Usage: odin run . -- <file_path>")
		os.exit(1)
	}

	packages, err := parse_file(os.args[1])
	if err != nil {
		fmt.println("Failed to parse file:", err)
		os.exit(1)
	}

	for &pkg in packages {
		if !repository.validate_package(&pkg) {
			fmt.println("Invalid package:", pkg)
			continue
		}
		fmt.printfln(
			"Package: %s, URL: %s, Build Command: %s",
			pkg.name,
			pkg.url,
			pkg.build_command,
		)
	}
}
