#!/usr/bin/perl
# by Yuriy Kolodovskyy aka Lexx
# lexx@ukrindex.com
# +380445924814
# last 20130305

use Time::localtime;
use Time::Local;
use MIME::Base64;
use DBI;
use CGI;

$main_config = '/usr/local/nodeny/nodeny.cfg.pl';
$call_pl = "/usr/local/nodeny/web/calls.pl";
$log_file='/usr/local/nodeny/module/ibox.log';

$category = '94';

sub Log
{
    my ($time);
    open LOG, ">>$log_file";
    $time = CORE::localtime;
    print LOG "$time: $_[0]\n";
    close LOG;
}

sub Ret
{
    $id_pay = 0 if !$id_pay;
    &Log($_[1]) if $_[1];
    print "Content-type: text/xml\n\n";
    print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print "<response>\n";
    print "\t<ibox_txn_id>" . $cgi->param('txn_id') . "</ibox_txn_id>\n" if $cgi->param('txn_id');
    print "\t<prv_txn>" . time . "</prv_txn>\n" if $cgi->param('command') eq 'pay' && $_[0] == 0;
    print "<prv_txn_date>$txn_date</prv_txn_date>\n" if $txn_date && $_[0] == 0;
    print "\t<sum>" . $cgi->param('sum') . "</sum>\n" if $cgi->param('sum');
    print "\t<result>$_[0]</result>\n";
    if (defined($_[2])) {
      print "\t<fields>\n";
      print "\t\t<field1 name=\"fio\">" . $_[2] . "</field1>\n";
      print "\t</fields>\n";
    }
    print "</response>\n";
    exit;
}

$cgi=new CGI;

$command = $cgi->param('command');
&Ret(2, 'Wrong command: ' . $command) unless ($command eq 'check' || $command eq 'pay');
$sum = $cgi->param('sum');
&Ret(2, 'Wrong sum: ' . $sum) unless ($command eq 'check' || ($command eq 'pay' && $sum=~/^\d{1,6}(\.\d+)?$/));
$txn_id = $cgi->param('txn_id');
&Ret(2, 'Wrong txn_id: ' . $txn_id) unless ($txn_id=~/^\d+$/);

$account = $cgi->param('account');
&Ret(2, 'Wrong account format') unless ($account=~/^\d+\d$/);
$sum1 = $account % 10;
$mid = int($account / 10);
$sum2=0;
$sum2+=$_ foreach split //, $mid;
$sum2%=10;
&Ret(2, 'Hashsum error for account: ' . $account) if $sum1!=$sum2;

&Ret(1, 'Main config not found') unless -e $main_config;
require $main_config;
&Ret(1, 'Call.pl not found') unless -e $call_pl;
require $call_pl;

$dbh=DBI->connect("DBI:mysql:database=$db_name;host=$db_server;mysql_connect_timeout=$mysql_connect_timeout;",
		  $user,$pw,{PrintError=>1});
&Ret(503, 'Could not connect to database') unless $dbh;
$dbh->do('SET NAMES UTF8');

$p=&sql_select_line($dbh,"SELECT * FROM users WHERE id='$mid' AND mid='0'");
&Ret(2, 'Account not found: ' . $account) unless $p;
&Ret(0, 'Account exist: ' . $account, $p->{fio}) if $command eq 'check';

$txn_date = $cgi->param('txn_date');
&Ret(2, 'Wrong txn_date: ' . $txn_date) unless ($txn_date=~/^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/);
$txn_date = "$1-$2-$3 $4:$5:$6";

$pp = &sql_select_line($dbh, "SELECT * FROM pays WHERE category='$category' AND reason='$txn_id'");
&Ret(0, 'Payment already exist with txn_id: ' . $txn_id) if $pp;

$sum_ok = $sum > 0 ? 1 : 0;

$sum_ok && $dbh->do("INSERT INTO pays SET 
    mid='$mid',
    cash='$sum',
    time=UNIX_TIMESTAMP('$txn_date'),
    admin_id=0,
    admin_ip=0,
    office=0,
    bonus='y',
    reason='$txn_id',
    coment='IBOX ($txn_id)',
    type=10,
    category=$category");
$sum_ok && $dbh->do("UPDATE users SET state='on', balance=balance+$sum WHERE id='$mid'");
$sum_ok && $dbh->do("UPDATE users SET state='on' WHERE mid='$mid'");

&Ret(0, "Pay added to billing account:$account txn_id:$id_payment txn_date:$txn_date sum:$sum" . ($sum_ok ? '' : " (WANRING: sum is 0)"));
