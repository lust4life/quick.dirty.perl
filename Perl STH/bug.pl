use strict;
use warnings;

use LWP::UserAgent;
use URI::Escape qw(uri_escape);

my @keywords = qw(
                     mambo
                     joomla
                     drupal
                     wordpress
                     struts
                     spring
                     rails
                     r
                     flash
                     actionscript
                     clojure
                     perl
                     php
                     python
                     java
                     javascript
                     node.js
                     go
                     golang
                     ruby
                     c
                     c++
                     basic
                     cobol
                     lua
                     lisp
                     erlang
                     haskell
                     nginx
                     apache
                     squid
                     linux
                     android
                     ios
                     objective-c
                     object-c
                     arm
                     angular
                     angularjs
                     );

push @keywords, 'c#';

my %results;
my $ua = LWP::UserAgent->new;
for my $keyword (@keywords) {
#    my $res = $ua->get('http://www.chinahr.com/so/'. uri_escape($keyword) .'/0-0-0-0-0-0-0-0-0-0-0-0-0-0/p0');
    my $res = $ua->get('http://search.51job.com/jobsearch/search_result.php?fromJs=1&jobarea=000000%2C00&funtype=0000&industrytype=00&keyword='.uri_escape($keyword).'&keywordtype=2&lang=c&stype=1&postchannel=0000&fromType=1');
#    if ($res->is_success && $res->content =~ m{1/(\d+)}) {
    if ($res->is_success && $res->content =~ m{ / (\d+)</td>}) {
        print $keyword, "\t", $1, "\n";
        $results{$keyword} = $1;
    } else {
        print $keyword, "\t", 'error', "\n";
    }
}

print "-" x 80, "\n";

for my $keyword(sort {$results{$b} <=> $results{$a}} keys %results) {
    print sprintf("%20s\t%d\n", $keyword, $results{$keyword});
}