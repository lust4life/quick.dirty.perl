#!/usr/bin/perl
# use 5.010;
use strict;
use warnings;
use HTML::SimpleLinkExtor;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use threads;  
use Thread::Semaphore;

mkdir 'D:\bt' unless -e 'D:\bt';

my $s = Thread::Semaphore->new( 3 );
 
my $btgc = 'http://we.99bitgongchang.com/';
my @links = &get_links( "$btgc/00/0404.html" );
      @links = grep { /p2p/ } @links;
      @links = map { $btgc.$_ } @links;

foreach( @links ){
      print "$_\n";
     m#(?<=\/)([\d-]+)(?=\.html)#;
     my $dir = 'e:\bt'."\\".$1;
     mkdir $dir;
     my @btlinks;  
      @btlinks = &get_links( $_ );
      @btlinks = grep { /file\.php/ } @btlinks;
      print join "\n",@btlinks;
      print "\n";
    foreach( @btlinks ){
           $s -> down(1); 
           threads -> create( \&down_bt,$_,$dir )->detach(); 
           $s -> up(1);  
      }
}


sub get_links{
      my $url = shift @_ or die "Hey,gimme a URL";
      my $ua = LWP::UserAgent -> new;
            $ua -> timeout(10);
                
      my $response = $ua->get( $url )  or die "Could not get '$url'";
      unless( $response -> is_success ){
                  die $response -> status_line;
                  }
      my $html = $response -> decoded_content;
      my $extractor = HTML::SimpleLinkExtor -> new;
            $extractor -> parse( $html );
            return $extractor -> links;
     }
     
sub down_bt{
        $s -> down(1); 
      my $btlink = shift @_ or die "Hey,gimme a URL";
            $btlink =~m#(http://[^/]+/\w+/)file\.php/(\w+)\.html#;
      my $down_link = $1;
      my $sn = $2;
      my $ua = LWP::UserAgent -> new();
            $ua -> timeout(60); 
            # $ua->proxy(['http', 'ftp'], 'http://127.0.0.1:8087/');
      my $url = $down_link.'down.php';
      my $arg = { 'type' => 'torrent',
                      'id' => $sn,
                      'name' => $sn
                     };
      my $resp = $ua->post( $url , $arg , 'Content_Type' => 'form-data' );
      my $filename = $arg ->{ name };
      my $dir = shift;
      open( my $fh,">","$dir\\$filename.torrent" );
      binmode( $fh );
      print  $fh $resp -> content;
      print "Have downloaded  $dir\\$filename.torrent\n";
      close $fh;
      $s -> up(1);  
}
