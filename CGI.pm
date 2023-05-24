package CGI;

our @EXPORT	= qw(validate_input, parse_form_data, headers, show_error, save_to_session, get_from_session, destroy_session);

my $SESSION_DIR = "/sessions";
my $TEMPLATE_DIR = "../templates/";


sub validate_input
{
	return ($_[0] =~ /^[_\-\.@a-zA-Z0-9]+$/);

}


sub redirect_url
{
	$url = $_[0];
	print("Status: 301 Moved Permanently\nLocation: $url\nContent-Type: text/html; charset=UTF-8\n\n");

}


sub destroy_session
{
	my $session = &get_cookie("session");
	if($session eq ""){
		return;
	}
	&set_cookie("session", "");
	my $session_path = "$SESSION_DIR/$session";
	system("rm -r $session_path");
}

sub get_session
{
	my $session = &get_cookie("session");
	if($session eq "") {
		$session = &generate_session_key;
		set_cookie("session", $session);		
	}
	return $session;
	
}

sub save_to_session
{

	my $session = &get_session;
	my $s_dir = "$SESSION_DIR/$session";


	mkdir $s_dir,0750;

	my $name = $_[0];
	my $value = $_[1];
	#my $out = `echo "$value" > "$s_dir/$name"`;	
	open(my $fh, '>', "$s_dir/$name") or die "whoops";
	print $fh $value;
	close(fh);
}

sub get_from_session
{
	my $name = $_[0];
	my $session = &get_session;
	my $s_val_file = "$SESSION_DIR/$session/$name";

	if(-e $s_val_file){
		open(my $fh, '<', $s_val_file) or die "whoops!";
		my $val = do { local $/; <$fh> };
		close $fh;
		return $val;
		#return `cat $s_val_file`;
	}	
	
	return "";
}

sub generate_session_key
{
	$key = "";
	@chars = ('0'..'9', 'A'..'F');
	$len = 128;
	srand;
	while($len--){ $key .= $chars[rand @chars] };

	return $key;
}


sub show_error
{
	$msg = $_[0];
	&headers;
	print $msg."\n";
}

sub set_cookie
{
	$name = $_[0];
	$value = $_[1];

	print "Set-Cookie:$name = $value; path=/;\n";
}

sub get_cookie
{
	$name = $_[0];
	$val = "";
	$rcvd_cookies = $ENV{'HTTP_COOKIE'};
	@cookies = split /;/, $rcvd_cookies;
	foreach $cookie ( @cookies ) {
		($key, $val) = split(/=/,$cookie);
		if($key eq $name){
			return $val;
		}
	}
	return $val;
	
}

sub parse_form_data
{
    local (*FORM_DATA) = @_;
    local ( $request_method, $query_string, @key_value_pairs,
                  $key_value, $key, $value);


	$request_method = $ENV{'REQUEST_METHOD'};
    	if ($request_method eq "GET") {
        	$query_string = $ENV{'QUERY_STRING'};
    	} elsif ($request_method eq "POST") {
        	read (STDIN, $query_string, $ENV{'CONTENT_LENGTH'});
    	} else {
        	print(500, "Server Error",
                            "Server uses unsupported method");
    	}

	@key_value_pairs = split (/&/, $query_string);
    	foreach $key_value (@key_value_pairs) {
        	($key, $value) = split (/=/, $key_value);
        	$value =~ tr/+/ /;
        	$value =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex ($1))/eg;


		if (defined($FORM_DATA{$key})) {
            		$FORM_DATA{$key} = join ("\0", $FORM_DATA{$key}, $value);
        	} else {
                    $FORM_DATA{$key} = $value;
        	}
    	}
};


sub headers{
	print <<'END';
Content-type: text/html


END
}

END{}

1;
