package App::Homely {
    use 5.016; 
    
    our $AUTHORITY = 'cpan:MAROS';
    our $VERSION = '1.00';
    
    # Prevent Mojolicious from tampering with @ARGV
    BEGIN {
        use MooseX::App::ParsedArgv;
        MooseX::App::ParsedArgv->instance;
    };
    
    use MooseX::App::Simple qw(Color);
    with qw(App::Homely::Role::Common);
    
    use App::Homely::Core;
    
    option '+config_file' => (
        cmd_flag        => 'config',
    );
    
    option '+debug' => ();
    
    sub run {
        my ($self) = @_;
        
        App::Homely::Core->new(
            debug       => $self->debug,
            config_file => $self->config_file,
        )->run();
    }
}

=encoding utf8

=head1 NAME

App::Homely - Description

=head1 SYNOPSIS

  bash> homely

=head1 DESCRIPTION

=head1 METHODS

=head2 Constructors

=head2 Accessors 

=head2 Methods

=head1 EXAMPLE

=head1 CAVEATS 

=head1 SEE ALSO

=head1 SUPPORT

Please report any bugs or feature requests to 
C<bug-TEMPLATE@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=TEMPLATE>.  
I will be notified, and then you'll automatically be notified of progress on 
your report as I make changes.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=head1 COPYRIGHT

TEMPLATE is Copyright (c) 2012 Maroš Kollár.

This library is free software and may be distributed under the same terms as 
perl itself. The full text of the licence can be found in the LICENCE file 
included with this module.

=cut

1;