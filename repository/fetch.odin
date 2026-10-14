package repository

import "core:fmt"
import "core:os"
import "core:strings"


FetchSourceError :: enum {
	nil,
	Failed_To_Fetch_Source_Code,
	Not_Git_Repo,
}

BuildFromSourceError :: enum {
	nil,
	Failed_To_Build_From_Source,
}


get_source_code :: proc(url: string, target_dir: string) -> FetchSourceError {
	if !strings.ends_with(url, ".git") {
		return FetchSourceError.Not_Git_Repo
	}

	r, w, err := os.pipe()
	if err != nil {
		return FetchSourceError.Failed_To_Fetch_Source_Code
	}
	defer os.close(r)

	command: [dynamic]string
	append(&command, "git", "clone", url)
	if target_dir != "" {
		append(&command, target_dir)
	}

	p: os.Process
	{
		defer os.close(w)
		// Command and arguments are broken up into elements
		p, err = os.process_start({command = command[:], stdout = w})
		if err != nil {
			return FetchSourceError.Failed_To_Fetch_Source_Code
		}
	}

	// Read the output captured in the pipe
	output, read_err := os.read_entire_file(r, context.temp_allocator)
	if read_err != nil {
		return FetchSourceError.Failed_To_Fetch_Source_Code
	}
	_, exec_err := os.process_wait(p)
	if exec_err != nil {
		return FetchSourceError.Failed_To_Fetch_Source_Code
	}

	fmt.print(string(output))

	return FetchSourceError.nil
}

build_from_source :: proc(build_command: string) -> BuildFromSourceError {
	r, w, err := os.pipe()
	if err != nil {
		return BuildFromSourceError.Failed_To_Build_From_Source
	}
	defer os.close(r)

	p: os.Process
	{
		defer os.close(w)
		// Command and arguments are broken up into elements
		p, err = os.process_start({command = {build_command}, stdout = w})
		if err != nil {
			return BuildFromSourceError.Failed_To_Build_From_Source
		}
	}

	return BuildFromSourceError.nil
}
