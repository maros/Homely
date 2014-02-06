package App::Homely::Web::Base {
    use 5.016;
    use warnings;
    
    use Mojo::Base 'Mojolicious::Controller';
    
    sub dashboard {
        my $self = shift;
        # Render template "example/welcome.html.ep" with message
        $self->render(msg => 'Hi');
    }
}

1;