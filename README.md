# NAME

Selenium::Screenshot - Compare and contrast screenshots in PNG format

# VERSION

version 0.001

# ATTRIBUTES

## png

REQUIRED - A base64 encoded string representation of a png. For
example, the string that the Selenium Webdriver server returns when
you invoke the ["screenshot" in Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver#screenshot) method.

## folder

OPTIONAL - a string where you'd like to save the screenshots on your
local machine. It will be ["abs\_path" in Cwd](https://metacpan.org/pod/Cwd#abs_path)'d and we'll try to save
there.

## metadata

OPTIONAL - provide a HASHREF of any additional data you'd like to use
in the filename. They'll be appended together in the filename of this
screenshot. Rudimentary sanitization is applied to the values of the
hashref, but it's not very clever and is probably easily subverted -
characters besides letters, numbers, dashes, and periods are
regex-substituted by '-' in the filename.

    my $screenshot = Selenium::Screenshot->new(
        png => $encoded,
        metadata => {
            url     => 'http://fake.url.com',
            build   => 'random-12347102.238402-build',
            browser => 'firefox'
        }
    );

## threshold

OPTIONAL - set the threshold at which images should be considered the
same. The range is from 0 to 100; for comparison, these two images are
N percent different, and these two images are N percent different.

# METHODS

## save

Persist your screenshot to disk. Without any arguments, we'll try to
build a filename from your metadata if you provided any, and the
timestamp if you didn't provide any metadata. You probably want to
provide metadata; timestamps aren't very evocative.

## filename

Get the filename that we constructed for this screenshot.

# BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/gempesaw/Selenium-Screenshot/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
