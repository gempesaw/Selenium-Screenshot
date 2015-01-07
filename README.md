# NAME

Selenium::Screenshot - Compare and contrast Webdriver screenshots in PNG format

[![Build Status](https://travis-ci.org/gempesaw/Selenium-Screenshot.svg?branch=master)](https://travis-ci.org/gempesaw/Selenium-Screenshot)

# VERSION

version 0.02

# SYNOPSIS

    my $driver = Selenium::Remote::Driver->new;
    $driver->get('http://www.google.com/404');

    my $orig = Selenium::Screenshot->new(
        png => $driver->screenshot,
        metadata => {
            build => 'prod',
            browser => 'firefox',
            'any metadata' => 'you might like'
        }
    );

    # Alter the page by turning the background blue
    $driver->execute_script('document.getElementsByTagName("body")[0].style.backgroundColor = "blue"');

    # Take another screenshot
    my $blue_file = Selenium::Screenshot->new(
        png => $driver->screenshot,
        metadata => {
            build => 'stage',
            bg => 'blue',
            url => 'http://www.google.com'
        }
    )->save;

    unless ($orig->compare($blue_file)) {
        my $diff_file = $orig->difference($blue_file);
        print 'The images differ; see ' . $diff_file . ' for details';
    }

# DESCRIPTION

Selenium::Screenshot is a wrapper class for [Image::Compare](https://metacpan.org/pod/Image::Compare). It
dumbly handles persisting your screenshots to disk and setting up the
parameters to [Image::Compare](https://metacpan.org/pod/Image::Compare) to allow you to extract difference
images between two states of your app. For example, you might be
interested in ensuring that your CSS refactor hasn't negatively
impacted other parts of your web app.

# INSTALLATION

This module depends on [Image::Compare](https://metacpan.org/pod/Image::Compare) for comparison, and
[Imager::File::PNG](https://metacpan.org/pod/Imager::File::PNG) for PNG support. The latter depends on
`libpng-devel`; consult <Image::Install>'s documentation and/or your
local googles on how to get the appropriate libraries installed on
your system. The following commands may be of aid on linux systems, or
they may not help at all:

    sudo apt-get install libpng-dev
    sudo yum install libpng-devel

For OS X, perhaps [this
page](http://ethan.tira-thompson.com/Mac_OS_X_Ports.html) may help.

# ATTRIBUTES

## png

REQUIRED - A base64 encoded string representation of a png. For
example, the string that the Selenium Webdriver server returns when
you invoke the ["screenshot" in Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver#screenshot) method.

## folder

OPTIONAL - a string where you'd like to save the screenshots on your
local machine. It will be run through ["abs\_path" in Cwd](https://metacpan.org/pod/Cwd#abs_path) and we'll try to
save there. If you don't pass anything and you invoke ["save"](#save), we'll
try to save in `($pwd)/screenshots/*`, wherever that may be.

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
N percent different, and these two images are N percent different. The
default threshold is 5 out of 100.

# METHODS

## compare

`compare` requires one argument: the filename of a PNG to compare
against. It must be the exact same size as the PNG you passed in to
this instance of Screenshot. It returns a boolean as to whether the
images meet your ["threshold"](#threshold) for similarity.

## difference

`difference` requires one argument: the filename of a PNG to compare
against. Like ["compare"](#compare), the other file must contain a PNG of the
exact same size as the PNG you passed into this instance of
screenshot. Note that for larger images, this method will take
noticeably long to resolve.

The difference image is scaled from white for no change to fuschia for
100% change.

## save

    Persist your screenshot to disk. Without any arguments, we'll try to
  build a filename from your metadata if you provided any, and the
  timestamp if you didn't provide any metadata. You probably want to
  provide metadata; timestamps aren't very evocative.

By passing a hash to ["save"](#save), you can alter the filename - any
arguments passed here will be sorted by key and added to the filename
along with the metadata you passed in on instantiation. NB: the
arguments here will shadow the values passed in for metadata, so you
can override any/all of the metadata keys if you so wish.

    Selenium::Screenshot->new(
        png => $driver->screenshot,
        metadata => {
            key => 'value'
        }
    )->save; # screenshots/value.png

    Selenium::Screenshot->new(
        png => $driver->screenshot,
        metadata => {
            key => 'value'
        }
    )->save(key => 'override'); # screenshots/override.png

## filename

Get the filename that we constructed for this screenshot. If you
passed in a HASHREF to metadata in the constructor, we'll sort that by
key and concatenate the parts into the filename. If there's no
metadata, we'll use a timestamp for the filename.

If you pass in a HASH as an argument, it will be combined with the
metadata and override/shadow any keys that match.

    Selenium::Screenshot->new(
        png => $driver->screenshot
    )->filename; # screenshots/203523252.png

    Selenium::Screenshot->new(
        png => $driver->screenshot,
        metadata => {
            key => 'value'
        }
    )->filename; # screenshots/value.png

    Selenium::Screenshot->new(
        png => $driver->screenshot,
        metadata => {
            key => 'value'
        }
    )->filename(
        key => 'shadow'
    ); # screenshots/shadow.png

# SEE ALSO

Please see those modules/websites for more information related to this module.

- [Image::Compare](https://metacpan.org/pod/Image::Compare)
- [Image::Magick](https://metacpan.org/pod/Image::Magick)
- [Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver)
- [https://github.com/bslatkin/dpxdt](https://github.com/bslatkin/dpxdt)
- [https://github.com/facebook/huxley](https://github.com/facebook/huxley)
- [https://github.com/BBC-News/wraith](https://github.com/BBC-News/wraith)

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
