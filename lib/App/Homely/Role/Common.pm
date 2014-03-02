package App::Homely::Role::Common {
    use 5.016;
    
    use Moose::Role;
    
    use File::HomeDir qw();
    
    has 'config_file' => (
        is              => 'rw',
        isa             => 'Path::Class::File',
        documentation   => 'Location of the config file',
        default         => sub {
            return Path::Class::File->new(File::HomeDir->my_home.'/.homely/config.json'),
        },
    );
    
    has 'debug' => (
        is              => 'rw',
        isa             => 'Bool',
        documentation   => 'Enable debug mode',
        default         => 0,
    );
    
    sub config_dir {
        my ($self) = @_;
        return $self->config_file->dir;
    }
}

1;