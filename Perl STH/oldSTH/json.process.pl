use 5.16.0;
use JSON;

say "hello\n\n";
my %user_info_hash;
my $json = JSON->new->allow_nonref;
while(<DATA>){
  my ($user_id,$img_info) = split(/,/,$_,2);
  $user_id =~ s/"//g;
  $user_info_hash{$user_id} = $json->decode($img_info);
}

my $sql_file_name = 'update.famouse.advert.url.txt';
my $insert_sql;
foreach my $uid(keys %user_info_hash){
  my $url = $user_info_hash{$uid};
  $url = $1 if $url =~ m/"AdvertImgUrl":"(.*?)"/;
  $insert_sql .= qq(UPDATE gcrm.`zhaopin_account` z SET z.`advert_img_url` = '$url'  WHERE z.`user_id` = $uid AND z.`advert_img_url` = '';\n);
}

&write_sql($sql_file_name,$insert_sql);

sub write_sql{
  my ($sql_file_name,$insert_sql) = @_;
  unless(-e $sql_file_name){
    open(WFH,">$sql_file_name") or die "can not create $sql_file_name! => $!";
#    print WFH Encode::encode("gb2312",$insert_sql);
    print WFH $insert_sql;
    close WFH;
  }
  else{
    die "$sql_file_name is exist!! please check it .\n";
  }
}


__DATA__
"129718798","{\"AuditTime\":0,\"BannerImgUrl\":\"gjfs01/M00/B6/88/wKhxwVAaPNaTl7GuAABUtnf40OI207_960-130_9-1.jpg\",\"LogoImgUrl\":\"gjfs01/M00/B1/F2/wKhxwVAg56rVlCO4AAAYWucD0Pg421_120-40_9-1.gif\",\"AdvertImgUrl\":\"gjfs02/M01/77/3F/wKhzR1BER728hFYxAACoPTtzjSg450_374-250_9-1.jpg\",\"AdvertImgPosition\":1,\"LabelCityId\":55}"
"73929979","{\"AuditTime\":0,\"BannerImgUrl\":\"gjfs02/M00/92/7D/wKhzR1Bmk1CSRIQZAACOYrISpFs059_960-130_9-1.jpg\",\"LogoImgUrl\":\"gjfs02/M02/19/1D/wKhzRlByin2PPJq0AAAKWu,P20Y703_120-40_9-1.jpg\",\"AdvertImgUrl\":\"gjfs02/M03/53/E5/wKhzRlCE4HqxtvooAAB0Y7O4Pao814_374-250_9-1.jpg\",\"AdvertImgPosition\":1,\"LabelCityId\":155}"
"129718798","{\"AuditTime\":0,\"BannerImgUrl\":\"gjfs02/M03/AC/61/wKhzR1B-Z2KHyb8DAABUtnf40OI744_960-130_9-1.jpg\",\"LogoImgUrl\":\"gjfs02/M03/AC/58/wKhzR1B-Z0njyQahAAAYWucD0Pg923_120-40_9-1.gif\",\"AdvertImgUrl\":\"gjfs02/M03/22/D0/wKhzR1CE3HeCBvRVAACoPTtzjSg398_374-250_9-1.jpg\",\"AdvertImgPosition\":1,\"LabelCityId\":55}"
"117278470","{\"AuditTime\":0,\"BannerImgUrl\":\"gjfs02/M03/52/80/wKhzRlCE3JPDAZaKAAB0HatJ7gY749_960-130_9-1.jpg\",\"LogoImgUrl\":\"gjfs02/M03/A0/FA/wKhzR1B-SkXYh6IJAAALc4FIahU071_120-40_9-1.jpg\",\"AdvertImgUrl\":\"gjfs02/M03/28/66/wKhzR1CE6wfwcmItAAArLtZpZkE512_180-120_9-1.jpg\",\"AdvertImgPosition\":2,\"LabelCityId\":204}"
"102595818","{\"AuditTime\":0,\"BannerImgUrl\":\"gjfs02/M03/3F/33/wKhzR1CA8Py,II04AACCXH8Secs861_960-130_9-1.jpg\",\"LogoImgUrl\":\"gjfs02/M03/3F/39/wKhzR1CA8Q2sjBCAAAAJns1gQiY196_120-40_9-1.gif\",\"AdvertImgUrl\":\"gjfs02/M03/5B/E0/wKhzR1CF,WnCXyDFAACK,U955KY491_374-250_9-1.gif\",\"AdvertImgPosition\":1,\"LabelCityId\":56}"
"110067049","{\"AuditTime\":0,\"BannerImgUrl\":\"gjfs02/M02/A2/1B/wKhzRlBlcn,Bgm3-AABkDRBViBI634_960-130_9-1.jpg\",\"LogoImgUrl\":\"gjfs01/M00/51/F4/wKhxwVBlciz48EKgAAAObaKwIME825_120-40_9-1.jpg\",\"AdvertImgUrl\":\"gjfs02/M03/52/50/wKhzRlCE3ASOfU0EAAAbC8KpLeE635_180-120_9-1.jpg\",\"AdvertImgPosition\":2,\"LabelCityId\":55}"
"59822951","{\"AuditTime\":0,\"BannerImgUrl\":\"gjfs02/M03/60/78/wKhzRlCFAKGxw8SXAACx,doFfL4440_960-130_9-1.jpg\",\"LogoImgUrl\":\"gjfs02/M03/A3/4A/wKhzR1B-UEKOEE7PAAAO6pC6mlg272_120-40_9-1.jpg\",\"AdvertImgUrl\":\"gjfs02/M03/30/DE/wKhzR1CFALv4-B34AABtuudDtK8049_374-250_9-1.jpg\",\"AdvertImgPosition\":1,\"LabelCityId\":204}"
"45739142","{\"AuditTime\":0,\"BannerImgUrl\":\"gjfs02/M03/28/22/wKhzR1CE6lqg,zMTAABxPYGHcq8174_960-130_9-1.jpg\",\"LogoImgUrl\":\"gjfs02/M03/5F/A1/wKhzRlCE,ffH62rbAAAN01ERqDw650_120-40_9-1.jpg\",\"AdvertImgUrl\":\"gjfs02/M03/88/7F/wKhzRlCF-SWiifpFAAAY1opCdNQ535_180-120_9-1.jpg\",\"AdvertImgPosition\":2,\"LabelCityId\":204}"
"140791820","{\"AuditTime\":0,\"BannerImgUrl\":\"gjfs02/M03/56/54/wKhzRlCE5rywmKj0AACLXi8LRXQ879_960-130_9-1.jpg\",\"LogoImgUrl\":\"gjfs02/M03/26/AD/wKhzR1CE5r-eWyt4AAAM3kZbvkQ380_120-40_9-1.jpg\",\"AdvertImgUrl\":\"gjfs02/M03/26/AE/wKhzR1CE5sPM0asyAAAmYdr5aqk284_180-120_9-1.jpg\",\"AdvertImgPosition\":2,\"LabelCityId\":114}"
"145476035","{\"AuditTime\":0,\"BannerImgUrl\":\"gjfs02/M03/26/9E/wKhzR1CE5pq2MnwwAAA93YWNldw332_960-130_9-1.jpg\",\"LogoImgUrl\":\"gjfs02/M03/26/9F/wKhzR1CE5p6FByXbAAAMKTIRMgM805_120-40_9-1.jpg\",\"AdvertImgUrl\":\"gjfs02/M03/56/49/wKhzRlCE5qOMyfJFAAAe,Lbydpc752_180-120_9-1.jpg\",\"AdvertImgPosition\":2,\"LabelCityId\":114}"
"58395222","{\"AuditTime\":0,\"BannerImgUrl\":\"gjfs02/M03/70/24/wKhzRlCA9DqZAuulAAB-EFghpOo205_960-130_9-1.jpg\",\"LogoImgUrl\":\"gjfs02/M03/70/26/wKhzRlCA9D-BQ,HeAAALB1lR-Bg505_120-40_9-1.jpg\",\"AdvertImgUrl\":\"gjfs02/M03/40/82/wKhzR1CA9ESe,pNhAAAZjFM,aSQ796_180-120_9-1.jpg\",\"AdvertImgPosition\":2,\"LabelCityId\":114}"
"403385","{\"AuditTime\":0,\"BannerImgUrl\":\"gjfs02/M03/56/88/wKhzRlCE5zSGidPBAAB5grvH0mc891_960-130_9-1.jpg\",\"LogoImgUrl\":\"gjfs02/M03/56/8A/wKhzRlCE5zjA9UCVAAAT6grsE0g329_120-40_9-1.jpg\",\"AdvertImgUrl\":\"gjfs02/M03/56/8C/wKhzRlCE5z6A6,clAACOB,Mx-aM438_374-250_9-1.jpg\",\"AdvertImgPosition\":1,\"LabelCityId\":114}"
