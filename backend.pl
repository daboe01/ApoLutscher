#!/usr/local/ActivePerl-5.14/site/bin/morbo

use Mojolicious::Lite;
use Mojolicious::Plugin::Database;
use Mojolicious::Plugin::RenderFile;
use Mojo::JSON qw(decode_json encode_json);
use SQL::Abstract::More;
use Apache::Session::File;
use Data::Dumper;

plugin 'database', { 
            dsn      => 'dbi:Pg:dbname=konten;host=localhost',
            username => 'postgres',
            password => 'xxxxxxxx',
            options  => { 'pg_enable_utf8' => 1, AutoCommit => 1 },
            helper   => 'db'
};
plugin 'RenderFile';

###########################################
# generic dbi part

helper fetchFromTable => sub { my ($self, $table, $sessionid, $where)=@_;
    my $sql = SQL::Abstract::More->new;

    my $order_by=[];
    my @a;
    my($stmt, @bind) = $sql->select( -columns  => [qw/*/], -from => $table, -where=> $where);
    my $sth = $self->db->prepare($stmt);
    $sth->execute(@bind);
        
    while(my $c=$sth->fetchrow_hashref())
    {   push @a,$c;
    }
    return \@a;
};

# fetch all entities
get '/DBI/:table'=> sub
{   my $self = shift;
    my $table  = $self->param('table');
    my $sessionid  = $self->param('session');
    my $res=$self->fetchFromTable($table, $sessionid, {});
    $self-> render( json => $res);
};

# fetch entities by (foreign) key
get '/DBI/:table/:col/:pk' => [col=>qr/[a-z_0-9\s]+/, pk=>qr/[a-z0-9\s\-]+/i] => sub
{   my $self = shift;
    my $table  = $self->param('table');
    my $pk  =    $self->param('pk');
    my $col  =   $self->param('col');
    my $sessionid  = $self->param('session');
    my $res=$self->fetchFromTable($table, $sessionid, {$col=> $pk});
    $self-> render( json => $res);
};

helper getTypeHashForTable => sub { my ($self, $table)=@_;
    my $sth = $self->db->column_info('','',$table,'');
    my $info = $sth->fetchall_arrayref({});
    my $ret={};
    foreach (@$info)
    {   $ret->{$_->{COLUMN_NAME}}=$_->{TYPE_NAME};
    }
    return $ret;
};
        
# update
put '/DBI/:table/:pk/:key'=> [key=>qr/\d+/] => sub
{   my $self    = shift;
    my $table   = $self->param('table');
    my $pk      = $self->param('pk');
    my $key     = $self->param('key');
    my $sql     = SQL::Abstract->new;
    my $jsonR   = decode_json( $self->req->body  || '{}' );

    my  %session;
    my $sessionid=$self->param('session');
    tie %session, 'Apache::Session::File', $sessionid , {Transaction => 0};

    my $types = $self->getTypeHashForTable($table);
    for (keys %$jsonR)    ## support for nullifying dates and integers with empty string or special string NULL
    {
        $jsonR->{$_}= ($jsonR->{$_} =~/(^NULL$)|(^\s*$)/o && $types->{$_} !~/text|varchar/o )? undef : $jsonR->{$_} ;

        if ($types->{$_} =~/timestamp|date/o)
        {   $jsonR->{$_}=~s/^([0-9]{1,2})\.([0-9]{1,2})\.([0-9]{2,4})(.*)$/$3-$2-$1$4/ogs;
        }
    }

    my($stmt, @bind) = $sql->update($table, $jsonR, {$pk=>$key});
    my $sth = $self->db->prepare($stmt);
    $sth->execute(@bind);
    app->log->debug("err: ".$DBI::errstr ) if $DBI::errstr;
    my $ret={err=> $DBI::errstr};

    $self->render( json=> $ret);
};

helper mapTableNameForWriting => sub { my ($self, $table)=@_;
    return $table;
};
        
# insert
post '/DBI/:table/:pk'=> sub
{   my $self    = shift;
    my $table    = $self->param('table');
    my $pk        = $self->param('pk');
    my $sql = SQL::Abstract->new;
    my $jsonR   = decode_json( $self->req->body||'{}' );

    my  %session;
    my $sessionid=$self->param('session');
    tie %session, 'Apache::Session::File', $sessionid , {Transaction => 0};
    my $ldap = $session{username};

    my($stmt, @bind) = $sql->insert( $self->mapTableNameForWriting($table), $jsonR || {name=>'New'});
    my $sth = $self->db->prepare($stmt);
    $sth->execute(@bind);
    app->log->debug("err: ".$DBI::errstr ) if $DBI::errstr;
    my $valpk;
    $valpk = (exists $jsonR->{$pk})? $jsonR->{$pk}:$self->db->last_insert_id(undef, undef, $table, $pk);

    $self->render( json=>{err=> $DBI::errstr, pk => $valpk} );
};

# delete
del '/DBI/:table/:pk/:key'=> [key=>qr/\d+/] => sub
{   my $self    = shift;
    my $table    = $self->param('table');
    my $pk        = $self->param('pk');
    my $key        = $self->param('key');
    my $sql = SQL::Abstract->new;

    my  %session;
    my $sessionid=$self->param('session');
    tie %session, 'Apache::Session::File', $sessionid , {Transaction => 0};
    my $ldap = $session{username};

    my($stmt, @bind) = $sql->delete($table, {$pk=>$key});
    my $sth = $self->db->prepare($stmt);
    $sth->execute(@bind);
    app->log->debug("err: ".$DBI::errstr ) if $DBI::errstr;

    $self->render( json=>{err=> $DBI::errstr} );
};
                
###################################################################
# main()

system('/Applications/Postgres.app/Contents/Versions/9.3/bin/pg_ctl start -D/Users/daboe01/Library/Application\ Support/Postgres/var-9.3');

system('open http://localhost:3000/Frontend/index.html');

app->config(hypnotoad => {listen => ['http://*:3000'], workers => 10, proxy => 1, heartbeat_timeout=>1200, inactivity_timeout=> 1200});
app->start;
