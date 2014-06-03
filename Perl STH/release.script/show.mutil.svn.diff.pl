use 5.18.1;
use Encode;

my $total_diff = q();
while(<DATA>){
  chomp;
  my $result =  `svn diff -r 30413:30583 -x -b "$_"`;
  $total_diff .= decode("utf8",$result);
}

#my $str = "E:/workplace.*?trunk/";
my $str ="E:/workplace.*?V4/" ;
$total_diff =~ s{$str}{}g;

open(WRF,">jiajun.diff") or die "can not write."; 
say WRF $total_diff;
close WRF;
say "done";


#
__DATA__
E:/workplace/ganji_crm_v4/03 ����/trunk/�ϼ���CRMϵͳV4/Ganji.CRM.WebUI/Views/TradingCenter/DepositList.cshtml
E:/workplace/ganji_crm_v4/03 ����/trunk/�ϼ���CRMϵͳV4/Ganji.CRM.Model/ViewModels/TradingCenter/TCDepositRecordVM.cs
E:/workplace/ganji_crm_v4/03 ����/trunk/�ϼ���CRMϵͳV4/Ganji.CRM.Service/TradingCenter/TradingCenterService.cs
E:/workplace/ganji_crm_v4/03 ����/trunk/�ϼ���CRMϵͳV4/Ganji.CRM.WebUI/Controllers/TradingCenter/TradingCenterController.cs
E:/workplace/ganji_crm_v4/03 ����/trunk/�ϼ���CRMϵͳV4/Ganji.CRM.WebUI/Scripts/core.js
