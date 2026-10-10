package repository

import "core:fmt"
import "core:os"
import "core:text/regex"


is_ascii_letters :: proc(s: string) -> bool {
	for i := 0; i < len(s); i += 1 {
		b := s[i]
		is_upper := b >= 'A' && b <= 'Z'
		is_lower := b >= 'a' && b <= 'z'

		if !is_upper && !is_lower {
			return false
		}
	}
	return true
}


URL_PATTERN :: `^https?://`
URL_REGEX: regex.Regular_Expression
IS_URL_REGEX_INITIALIZED: bool = false

initialize_url_regex :: proc() -> regex.Regular_Expression {
	if !IS_URL_REGEX_INITIALIZED {
		url_regex, err := regex.create(URL_PATTERN)
		if err != nil {
			fmt.println("Failed to compile URL regex:", err)
			os.exit(1)
		}
		URL_REGEX = url_regex
		IS_URL_REGEX_INITIALIZED = true
	}
	return URL_REGEX
}
