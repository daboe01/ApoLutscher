#!/usr/bin/perl

use Mojo::UserAgent;
use Text::CSV_XS qw( csv );
use Data::Dumper;
use DateTime;
use SQL::Abstract;
use DBI;

use constant username => 'VRK00000000000';
use constant password => '000000';

sub getKontoumsaetze { my ($konto_index)=@_;
    my $ua = Mojo::UserAgent->new;

    my $loginpage= $ua->get('https://www.apobank.de/ptlweb/WebPortal?bankid=8008&trackid=piwikcfac54a14c67718e')->res->body;
    my ($postaction, $tk);
    $postaction = $1 if $loginpage=~qr{form name="form1" action="([^"]+)"};
    $tk = $1         if $loginpage=~qr{"tk" value="([^"]+)"};
    $postaction=~s/&amp;/&/ogs;


    my $landingpage = $ua->post('https://www.apobank.de'.$postaction => form =>
    {
        'vRKennungInpVO.strVrKennungOderAlias' => '',
        'pruefenPIN_V01_VO.strVrKennungOderAlias'=> username,
        'pruefenPIN_V01_VO.txtKkdPwTrp'=> password,
        '___pwdattrs___' => 'pruefenPIN_V01_VO.txtKkdPwTrp',
        'tag.accordion.collapse.VRK' => 'n',
        'tag.accordion.collapse.SIG' => 'j',
        'tk' => $tk,
        'event___login'=>'Login'
    })->res->body;

    my $export;
    $export = $1 if $landingpage=~qr{href="(.+?menupunkt=1\.1\.2\.2\.3\.2\.)"};
    $export=~s/&amp;/&/ogs;
    my $exportpage= $ua->get('https://www.apobank.de'.$export)->res->body;


    $postaction = $1 if $exportpage=~qr{form action="([^"]+)"};
    $postaction=~s/&amp;/&/ogs;

    $exportpage = $ua->post('https://www.apobank.de'.$postaction.'&event___idKontoGewaehlt=OK' => form =>
    {
        'idKontoGewaehlt' => $konto_index,
        'selectAutosubmit_Select_1'=> 'Select_1',
        'idUmsatzExportFormatSchluessel'=> '0',
        'selectAutosubmit_ID_INPUT_EXPORTFORMAT' => '',
        'datDatumVon' => '',
        'datDatumBis' =>  '',
    })->res->body;
    $postaction = $1 if $exportpage=~qr{form action="([^"]+)"};
    $postaction=~s/&amp;/&/ogs;

    my $export = $ua->post('https://www.apobank.de'.$postaction => form =>
    {
        'idKontoGewaehlt' => $konto_index,
        'selectAutosubmit_Select_1'=> '',
        'idUmsatzExportFormatSchluessel'=> '0',
        'selectAutosubmit_ID_INPUT_EXPORTFORMAT' => '',
        'datDatumVon' => '03.07.2006',
        'datDatumBis' =>  DateTime->now->strftime('%d.%m.%Y'),
        'event___exportieren'=>'Exportieren'
    })->res->content->asset->slurp;

    return [] if $export=~/<html/; # keine umsaetze

    $export=~s/W.hrung/Waehrung/;
    $export=~s/Textschl.ssel/Textschluessel/;
    $export=~s/Auftraggeber.+?nger/Name/;
    open my $fh, '<', \$export;
    return csv (in => $fh, sep_char=> ";", headers => "auto");
}

sub reformat_date { my ($datein)=@_;
    $datein=~s/^([0-9]{2})\.([0-9]{2})\.([0-9]{4})(.*)$/$3-$2-$1/ogs;
    return $datein;
}
sub reformat_betrag { my ($datein)=@_;
    $datein=~s/\.//ogs;
    $datein=~s/,/./ogs;
    return $datein;
}

sub hasRowAlready { my ($dbh, $row)=@_;
    my $sql = SQL::Abstract->new(quote_char=>'"');
	my($stmt, @bind) = $sql->select('umsaetze', ['id'], $row);
    my $sth = $dbh->prepare($stmt);
    $sth->execute(@bind);
    return $sth->fetchrow_hashref();
}

sub putKontoumsaetze { my ($umsatz_array)=@_;
   my $dbh = DBI->connect("dbi:Pg:dbname=konten;host=localhost", 'postgres', 'postgres') || warn "Database connection not made: $DBI::errstr";

   foreach my $row (@$umsatz_array)
   {
        next if exists $row->{''};
        $row->{Wertstellung}=reformat_date($row->{Wertstellung});
        $row->{Buchungstag}=reformat_date($row->{Buchungstag});
        $row->{Betrag}=reformat_betrag($row->{Betrag});
        $row->{Kontostand}=reformat_betrag($row->{Kontostand});
# warn Dumper $row;
        my $sql = SQL::Abstract->new(quote_char=>'"');
        ($stmt, @bind) = $sql->insert('umsaetze', $row);
        $sth = $dbh->prepare($stmt);
        $sth->execute(@bind) unless hasRowAlready($dbh, $row);
   }
}

foreach my $index (0..2){
    putKontoumsaetze(getKontoumsaetze($index));
}

exit(0);
