package App::Homely::Type {
    use 5.014;
    
    use Moose::Util::TypeConstraints;
    
    enum 'App::Homely::Type::Mode', [qw(manual gone_long gone_short present)];
    
    no Moose::Util::TypeConstraints;
}