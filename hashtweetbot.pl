#!/usr/bin/env perl
use strict;
use AnyEvent::Twitter::Stream;
use AnyEvent::IRC::Client;
use Encode;

my $conn = AnyEvent::IRC::Client->new;
$conn->connect($ENV{IRC_HOST}, $ENV{IRC_PORT} || 6667, { nick => $ENV{IRC_NICK}, user => "hashtweetbot" });
$conn->reg_cb(
    connect => sub {
        my $conn = shift;
        warn "Connected to IRC.\n";
        $conn->send_srv(JOIN => $ENV{IRC_CHANNEL});
    },
);

my $on_tweet = sub {
    my $tweet = shift;
    return if $tweet->{retweeted_status};

    my $text = sprintf '%s: %s https://twitter.com/%s/status/%s',
        $tweet->{user}{screen_name}, $tweet->{text},
        $tweet->{user}{screen_name}, $tweet->{id_str};

    $conn->send_chan($ENV{IRC_CHANNEL}, NOTICE => $ENV{IRC_CHANNEL}, Encode::encode_utf8($text));
};

my $g = AnyEvent::Twitter::Stream->new(
    username => $ENV{TWITTER_USERNAME},
    password => $ENV{TWITTER_PASSWORD},
    method => "filter",
    track  => $ENV{TWITTER_TRACK},
    on_tweet => $on_tweet,
);

AE::cv->recv;



