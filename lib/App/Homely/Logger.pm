package App::Homely::Logger {
    use 5.014;
    use warnings;
    
    use Log::Any::Adapter;
    
    Log::Any::Adapter->set('Stdout');
}

1;