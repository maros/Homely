package App::Homely::Logger {
    use 5.016;
    use warnings;
    
    use Log::Any::Adapter;
    
    Log::Any::Adapter->set('Stdout');
}

1;