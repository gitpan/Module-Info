package Foo;

$foo = 42;

{
    package Bar;

    $bar = 23;
}

sub wibble {
    package Wibble;
    return 66;
}
