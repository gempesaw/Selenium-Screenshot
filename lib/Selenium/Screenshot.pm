package Selenium::Screenshot;

# ABSTRACT: Compare and contrast Webdriver screenshots in PNG format
use Moo;
use Image::Compare;
use Imager qw/:handy/;
use Imager::Fountain;
use Carp qw/croak carp/;
use Cwd qw/abs_path/;
use MIME::Base64;

=for markdown [![Build Status](https://travis-ci.org/gempesaw/Selenium-Screenshot.svg?branch=master)](https://travis-ci.org/gempesaw/Selenium-Screenshot)

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Selenium::Screenshot is a wrapper class for L<Image::Compare>. It
dumbly handles persisting your screenshots to disk and setting up the
parameters to L<Image::Compare> to allow you to extract difference
images between two states of your app. For example, you might be
interested in ensuring that your CSS refactor hasn't negatively
impacted other parts of your web app.

=head1 INSTALLATION

This module depends on L<Image::Compare> for comparison, and
L<Imager::File::PNG> for PNG support. The latter depends on
C<libpng-devel>; consult your local googles on how to get the
appropriate libraries installed on your system. The following commands
may be of aid on linux systems, or they may not help at all:

    sudo apt-get install libpng-dev
    sudo yum install libpng-devel

For OS X, perhaps L<this
page|http://ethan.tira-thompson.com/Mac_OS_X_Ports.html> may help.

=attr png

REQUIRED - A base64 encoded string representation of a png. For
example, the string that the Selenium Webdriver server returns when
you invoke the L<Selenium::Remote::Driver/screenshot> method.

=cut

has png => (
    is => 'ro',
    coerce => sub {
        my ($encoded_png) = @_;

        return decode_base64($encoded_png);
    },
    required => 1
);

=attr folder

OPTIONAL - a string where you'd like to save the screenshots on your
local machine. It will be run through L<Cwd/abs_path> and we'll try to save
there.

=cut

has folder => (
    is => 'rw',
    coerce => sub {
        my ($folder) = @_;
        $folder //= 'screenshots/';
        mkdir $folder unless -d $folder;

        return abs_path($folder) . '/';
    },
    default => sub { 'screenshots/' }
);

=attr metadata

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

=cut

has metadata => (
    is => 'ro',
    lazy => 1,
    default => sub { '' },
    predicate => 'has_metadata'
);

=attr threshold

OPTIONAL - set the threshold at which images should be considered the
same. The range is from 0 to 100; for comparison, these two images are
N percent different, and these two images are N percent different. The
default threshold is 5 out of 100.

=cut

# TODO: add threshold tests
# TODO: provide reference images

has threshold => (
    is => 'ro',
    lazy => 1,
    coerce => sub {
        my ($threshold) = @_;

        my $scaling = 255 * sqrt(3) / 100;
        return $threshold * $scaling;
    },
    default => sub { 5 }
);

has _cmp => (
    is => 'ro',
    lazy => 1,
    init_arg => undef,
    builder => sub {
        my ($self) = @_;
        my $cmp = Image::Compare->new;
        $cmp->set_image1(
            img => $self->filename,
            type => 'png'
        );

        return $cmp;
    }
);

=method compare

C<compare> requires one argument: the filename of a PNG to compare
against. It must be the exact same size as the PNG you passed in to
this instance of Screenshot. It returns a boolean as to whether the
images meet your L</threshold> for similarity.

=cut

sub compare {
    my ($self, $opponent) = @_;
    die 'Don\'t know what to compare with' unless $opponent;

    $self->save;
    $self->_cmp->set_image2( img => $opponent );

    $self->_cmp->set_method(
        method => &Image::Compare::AVG_THRESHOLD,
        args   => {
            type  => &Image::Compare::AVG_THRESHOLD::MEAN,
            value => $self->threshold,
        }
    );

    return $self->_cmp->compare;
}

=method difference

C<difference> requires one argument: the filename of a PNG to compare
against. Like L</compare>, the other file must contain a PNG of the
exact same size as the PNG you passed into this instance of
screenshot. Note that for larger images, this method will take
noticeably long to resolve.

The difference image is scaled from white for no change to fuschia for
100% change.

=cut

sub difference {
    my ($self, $opponent) = @_;
    die 'Don\'t know what to compare with' unless $opponent;

    $self->_cmp->set_image2(
        img => $opponent
    );

    $self->_cmp->set_method(
        method => &Image::Compare::IMAGE,
        args => Imager::Fountain->simple(
            positions => [              0.0,            1.0],
            colors    => [NC(255, 255, 255), NC(240,18,190)]
        )
    );

    my $name = $self->filename('diff');
    my $diff = $self->_cmp->compare;
    $diff->write( file => $name );
    return $name;
}


=method save

Persist your screenshot to disk. Without any arguments, we'll try to
build a filename from your metadata if you provided any, and the
timestamp if you didn't provide any metadata. You probably want to
provide metadata; timestamps aren't very evocative.

=cut

sub save {
    my ($self) = @_;

    my $filename = $self->filename;
    open (my $fh, '>', $filename) or croak 'Couldn\'t open ' . $filename . ' for writing: ' . $!;
    binmode $fh;
    print $fh $self->png;
    close ($fh);

    return $filename;
}

=method filename

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

=cut

sub filename {
    my ($self, %overrides) = @_;

    my @filename_parts;
    if ($self->has_metadata or %overrides) {
        my $metadata = {
            %{ $self->metadata},
            %overrides
        };

        foreach (sort keys %{ $metadata }) {
            push @filename_parts, $self->_sanitize_string($metadata->{$_});
        }
    }
    else {
        push @filename_parts, time
    }

    my $filename = $self->folder . join('-', @filename_parts) . '.png';
    $filename =~ s/\-+/-/g;
    return $filename;
}

sub _sanitize_string {
    my ($self, $dirty_string) = @_;

    $dirty_string =~ s/[^A-z0-9\.\-]/-/g;
    return $dirty_string;
}

=head1 SEE ALSO

Image::Compare
Image::Magick
Selenium::Remote::Driver
https://github.com/bslatkin/dpxdt
https://github.com/facebook/huxley
https://github.com/BBC-News/wraith

=cut

1;
