package App::wordlist;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

sub _list_installed {
    require Module::List;
    my $mods = Module::List::list_modules(
        "Games::Word::Wordlist::",
        {
            list_modules  => 1,
            list_pod      => 0,
            recurse       => 1,
        });
    my $modsp = Module::List::list_modules(
        "Games::Word::Phraselist::",
        {
            list_modules  => 1,
            list_pod      => 0,
            recurse       => 1,
        });
    my $res = {}; # key=name, val=full module name
    for my $fullname (keys %$mods, keys(%$modsp)) {
        (my $shortname = $fullname) =~ s/^Games::Word::\w+list:://;
        if ($res->{$shortname}) {
            ($shortname = $fullname) =~ s/^Games::Word:://;
        }
        $res->{$shortname} = $fullname;
    }
    $res;
}

$SPEC{wordlist} = {
    v => 1.1,
    summary => 'Grep words from Games::Word::{Wordlist,Phraselist}::*',
    args => {
        arg => {
            schema => ['array*' => of => 'str*'],
            pos => 0,
            greedy => 1,
        },
        ignore_case => {
            schema  => 'bool',
            default => 1,
        },
        wordlist => {
            schema => ['array*' => of => 'str*'],
            summary => 'Select one or more wordlist modules',
            cmdline_aliases => {w=>{}},
        },
        or => {
            summary => 'Use OR logic instead of the default AND',
            schema  => 'bool',
        },
        action => {
            schema  => ['str*', in=>[
                'list_cpan', 'list_installed', 'install', 'uninstall',
                'grep',
            ]],
            default => 'grep',
            cmdline_aliases => {
                l => {
                    summary=>'List installed Games::Word::Wordlist::* modules',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'list_installed' },
                },
                L => {
                    summary=>'List Games::Word::Wordlist::* modules on CPAN',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'list_cpan' },
                },
                I => {
                    summary=>'Install Games::Word::Wordlist::* module',
                    code => sub { my $args=shift; $args->{action} = 'install' },
                },
                U => {
                    summary=>'Uninstall Games::Word::Wordlist::* module',
                    code => sub { my $args=shift; $args->{action} = 'uninstall' },
                },
            },
        },
        detail => {
            summary => 'Display more information when listing modules',
            schema  => 'bool',
        },
    },
    examples => [
        {
            argv => [],
            summary => 'By default print all words from all wordlists',
        },
        {
            argv => [qw/foo bar/],
            summary => 'Print all words matching /foo/ and /bar/',
        },
        {
            argv => [qw/--or foo bar/],
            summary => 'Print all words matching /foo/ or /bar/',
        },
        {
            argv => [qw/-w KBBI foo/],
            summary => 'Select a specific wordlist (multiple -w allowed)',
        },
        {
            argv => [qw|/fof[aeiou]/|],
            summary => 'Filter by regex',
        },
    ],
};
sub wordlist {
    my %args = @_;

    my $action = $args{action} // 'grep';
    my $list_installed = _list_installed();
    my $ci = $args{ignore_case} // 1;
    my $or = $args{or};
    my $arg = $args{arg} // [];

    if ($action eq 'grep') {

        # convert /.../ in arg to regex
        for (@$arg) {
            if (m!\A/(.+)/\z!) {
                $_ = $ci ? qr/$_/i : qr/$_/;
            } else {
                $_ = lc($_) if $ci;
            }
        }

        my @res;
        my $wordlists = $args{wordlist};
        if (!$wordlists || !@$wordlists) {
            $wordlists = [sort keys %$list_installed];
        }
        for my $wl (@$wordlists) {
            my $mod = $list_installed->{$wl} or
                return [400, "Unknown wordlist '$wl', see 'wordlist -l' ".
                            "for list of installed wordlists"];
            (my $modpm = $mod . ".pm") =~ s!::!/!g;
            require $modpm;
            my $obj = $mod->new;
            $obj->each_word(
                sub {
                    my $word = shift;
                    my $cmpword = $ci ? lc($word) : $word;
                    for (@$arg) {
                        my $match =
                            ref($_) eq 'Regexp' ? $cmpword =~ $_ :
                                index($cmpword, $_) >= 0;
                        if ($or) {
                            # succeed early when --or
                            if ($match) {
                                push @res, $word;
                                return;
                            }
                        } else {
                            # fail early when and (the default)
                            if (!$match) {
                                return;
                            }
                        }
                    }
                    if (!$or || !@$arg) {
                        push @res, $word;
                    }
                }
            );
        }
        [200, "OK", \@res];

    } elsif ($action eq 'list_installed') {

        my @res;
        for (sort keys %$list_installed) {
            if ($args{detail}) {
                push @res, {
                    name   => $_,
                    module => $list_installed->{$_},
                };
            } else {
                push @res, $_;
            }
        }
        [200, "OK", \@res];

    } elsif ($action eq 'list_cpan') {

        [501, "Not yet implemented"];

    } elsif ($action eq 'install') {

        [501, "Not yet implemented"];

    } elsif ($action eq 'uninstall') {

        [501, "Not yet implemented"];

    } else {

        [400, "Unknown action '$action'"];

    }
}

1;
# ABSTRACT: Grep words from Games::Word::{Wordlist,Phraselist}::*

=head1 SYNOPSIS

See the included script L<wordlist>.


=head1 TODO

In -l --detail, show summary (extract from POD Name or # ABSTRACT).

Support Games::Word::Phraselist::*

Option --random (plus -n) to generate (or n) random word(s).

Option -v (--invert-match) like grep.

Implement -n (max result).


=head1 SEE ALSO

L<Games::Word::Wordlist>

L<Games::Word::Phraselist>

