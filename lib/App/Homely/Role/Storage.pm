package App::Homely::Role::Storage {
    use 5.016;
    
    use utf8;
    
    use namespace::autoclean;
    use Moose::Role;
    requires qw(moniker);
    
    use Sereal::Encoder qw(encode_sereal);
    use Sereal::Decoder qw(decode_sereal);
    
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
        
        my %storage;
        foreach my $attribute ($self->meta->get_all_attributes) {
            next
                if $attribute->does('Homely::Meta::Attribute::DoNotStore');
            $storage{$attribute->name} = $attribute->get_raw_value($self);
        }
        
        my $encoded = encode_sereal(\%storage);
        my $file = $self->storage_filename($identifier);
        $file->spew($encoded);
    }
    
    sub load {
        my ($class,$identifier) = @_;
        
        my $file = $class->storage_filename($identifier);
        my $encoded = $file->slurp();
        my $storage = decode_sereal($encoded);
        
        $class = ref($class) 
            if blessed $class;
        return bless($storage,$class);
    }
}

1;