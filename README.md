# NAME

Selenium::Screenshot - Compare and contrast Webdriver screenshots in PNG format

[![Build Status](https://travis-ci.org/gempesaw/Selenium-Screenshot.svg?branch=master)](https://travis-ci.org/gempesaw/Selenium-Screenshot)

# VERSION

version 0.08

# SYNOPSIS

    my $driver = Selenium::Remote::Driver->new;
    $driver->set_window_size(320, 480);
    $driver->get('http://www.google.com/404');

    my $white = Selenium::Screenshot->new(png => $driver->screenshot);

    # Alter the page by turning the background blue
    $driver->execute_script('document.getElementsByTagName("body")[0].style.backgroundColor = "blue"');

    # Take another screenshot
    my $blue = Selenium::Screenshot->new(png => $driver->screenshot);

    unless ($white->compare($blue)) {
        my $diff_file = $white->difference($blue);
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
`libpng-devel`; consult [Image::Install](https://metacpan.org/pod/Image::Install)'s documentation and/or your
local googles on how to get the appropriate libraries installed on
your system. The following commands may be of aid on linux systems, or
they may not help at all:

    sudo apt-get install libpng-dev
    sudo yum install libpng-devel

For OS X, perhaps [this
page](http://ethan.tira-thompson.com/Mac_OS_X_Ports.html) may help.

# ATTRIBUTES

## png

REQUIRED - A base64 encoded string representation of a PNG. For
example, the string that the Selenium Webdriver server returns when
you invoke the ["screenshot" in Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver#screenshot) method. After
being passed to our constructor, this will be automatically
instantiated into an Imager object: that is, `$screenshot->png`
will return an Imager object.

If you are so inclined, you may also pass an Imager object instead of
a base64 encoded PNG.

## exclude

OPTIONAL - Handle dynamic parts of your website by specify areas of the
screenshot to black out before comparison. We're working on
simplifying this data structure as much as possible, but it's a bit
complicated to handle the output of the functions from
Selenium::Remote::WebElement. If you have WebElements already found
and instantiated, you can do:

    my $elem = $driver->find_element('div', 'css');
    Selenium::Screenshot->new(
        png => $driver->screenshot,
        exclude => [{
            size      => $elem->get_size,
            location  => $elem->get_element_location
        }]
    );

To construct the exclusions by hand, you can do:

    Selenium::Screenshot->new(
        png => $driver->screenshot,
        exclude => [{
            size     => { width => 10, height => 10 }
            location => { x => 5, y => 5 },
        }]
    );

This would black out a 10x10 box with its top left corner 5 pixels
from the top edge and 5 pixels from the left edge of the image.

You may pass more than one rectangle at a time.

Unfortunately, while we would like to accept CSS selectors, it feels a
bit wrong to have to obtain the element's size and location from this
module, which would make a binding dependency on
Selenium::Remote::WebElement's interface. Although this is more
cumbersome, it's a cleaner separation. In case you need help
generating your exclude data structure, the following map might help:

    my @elems = $d->find_elements('p', 'css');
    my @exclude = map {
        my $rect = {
            size => $_->get_size,
            location => $_->get_element_location
        };
        $rect
    } @elems;
    my $s = Selenium::Screenshot->new(
        png => $d->screenshot,
        exclude => [ @exclude ],
    );

## threshold

OPTIONAL - set the threshold at which images should be considered the
same. The range is from 0 to 100; for comparison, these two images are
N percent different, and these two images are N percent different. The
default threshold is 5 out of 100.

## folder

OPTIONAL - a string where you'd like to save the screenshots on your
local machine. It will be run through ["abs\_path" in Cwd](https://metacpan.org/pod/Cwd#abs_path) and we'll try to
save there. If you don't pass anything and you invoke ["save"](#save), we'll
try to save in `($pwd)/screenshots/`, wherever that may be.

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

## target

Pass in a hashref with the size and location of the element you'd like
to target. This can be useful if you want to assert that a particular
element on your page stays the same across builds.

Again, like in the case for ["exclude"](#exclude), we'd like to make this easier
for you but unfortunately we're uncomfortable directly invoking the
methods on WebElement ourselves. For the time being, you'll have to
provide this awkward HoH to specify a target.

    my $elem = $driver->find_element($locator, $by);
    my $s = Selenium::Screenshot->new(
        png => $d->screenshot,
        target => {
            size => $elem->get_size,
            location => $elem->get_element_location_in_view
        }
    );

The screenshot will be cropped to the resulting dimensions as
specified by the size and element location. Note that you will have to
sort out issues when the element is not immediately displayed on the
screen by invoking
["get\_element\_location\_in\_view" in Selenium::Remote::WebElement](https://metacpan.org/pod/Selenium::Remote::WebElement#get_element_location_in_view). This is
especially true if you're using ["target"](#target) along with ["exclude"](#exclude), as
the locations of the elements you're excluding will surely change
after scrolling to bring your targeted element in to view.

# METHODS

## compare

`compare` takes zero or one arguments with drastically different
behavior in each case.

If you invoke it without an argument, we'll try to find a reference as
described in ["reference"](#reference). If we don't find a reference screenshot,
we'll ["carp" in Carp](https://metacpan.org/pod/Carp#carp) about it and save the current screenshot as a
reference and return the result of attempting to save the
reference. That means that your first time running `compare` without
an argument, it may return something truthy, even though we haven't
compared anything to anything.

If we are able to find a reference in the expected spot, we'll compare
the current screenshot to that reference and return a boolean as to
the comparison.

If you pass in one argument, it must be one of the following: the
filename, Imager object, or Selenium::Screenshot of a PNG to compare
against. It must be the exact same size as the PNG you passed in to
this instance of Screenshot. It returns a boolean as to whether the
images meet your ["threshold"](#threshold) for similarity.

## difference

`difference` requires one argument: the filename of a PNG, an Imager
object, or a Selenium::Screenshot object instantiated from such a
PNG. Like ["compare"](#compare), the opponent image MUST be a PNG of the exact
same size as the PNG you passed into this instance of screenshot. Note
that for larger images, this method will take noticeably longer to
resolve.

This will return the filename to which the difference image has been
saved - it will be a copy of the opponent image overlaid with the
difference between the two images. The filename of the difference
image is computed via the metadata provided during instantiation, with
\-diff suffixed as the final component.

    my $diff_file = $screenshot->difference($oppoent);
    `open $diff_file`;

## find\_opponent

Takes no arguments. Searches in ["folder"](#folder) for a reference image to
either do difference or comparison. If a reference png is found, an
Imager object of that file is returned.

Feel free to subclass Selenium::Screenshot and override this method
with your own routine to find your reference file, wherever it may be
located (AWS, database, etc). We return an Imager object internally,
but we'll also accept a filename to the .png somewhere on your local
machine.

This function is invoked if you call ["compare"](#compare) with no arguments.

## filename

Get the filename that we constructed for this screenshot. If you
passed in a HASHREF to metadata in the constructor, we'll sort that by
key and concatenate the parts into the filename. If there's no
metadata, we'll use a timestamp for the filename.

If you pass in a HASH as an argument, it will be combined with the
metadata and override/shadow any keys that match.

    # default behavior is to use the timestamp
    Selenium::Screenshot->new(
        png => $driver->screenshot
    )->filename; # screenshots/203523252.png

    # providing any metadata uses that as the filename, and the basis
    # for the diff filename
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
    )->difference($opponent); # screenshots/value-diff.png

    # overriding the filename
    Selenium::Screenshot->new(
        png => $driver->screenshot,
        metadata => {
            key => 'value'
        }
    )->filename(
        key => 'shadow'
    ); # screenshots/shadow.png

## reference

Returns a STRING using the ["metadata"](#metadata) and ["folder"](#folder), but with
\-reference appended to the very end. This is the file that ["compare"](#compare)
will look for automatically, if it is not passed any arguments.

## save

Delegates to ["write" in Imager](https://metacpan.org/pod/Imager#write), which it uses to write to the filename
as calculated by ["filename"](#filename). Like ["filename"](#filename), you can pass in a
HASH of overrides to the filename if you'd like to customize it.

## save\_reference

Saves a file according to the ["metadata"](#metadata) and ["folder"](#folder) options with
\-reference suffixed to the end of it. By default, ["compare"](#compare) will
look for this file if it receives no arguments.

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

# CONTRIBUTOR

Nicolas Georges <xlat@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
