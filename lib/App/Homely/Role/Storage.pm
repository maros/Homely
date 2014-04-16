package App::Homely::Role::Storage {
    use 5.014;
    
    use utf8;
    
    use namespace::autoclean;
    use Moose::Role;
    use MooseX::Storage;
    with Storage('format' => 'JSON');
    requires qw(moniker);
    
    MooseX::Storage::Engine->add_custom_type_handler(
        'DateTime' => (
            expand   => sub { DateTime->from_epoch( epoch => shift, time_zone => App::Homely::Core->instance->timezone ) },
            collapse => sub { (shift)->epoch }, 
        )
    );
    
    sub storage_filename {
        my ($self,$identifier) = @_;
        
        my $name = $self->moniker;
        if (defined $identifier) {
            $name .= '_'.$identifier;
        }
        $name .= '.ser';
        return App::Homely::Core->instance->config_dir->file($name);
    }
    
    sub store {
        my ($self,$identifier) = @_;
        my $file = $self->storage_filename($identifier);
        $file->spew($self->freeze);
    }
    
    sub load {
        my ($class,$identifier) = @_;
        
        $class = ref($class) 
            if blessed $class;

        my $file = $class->storage_filename($identifier);
        return $class->thaw(  $file->slurp() );      
    }
}

1;