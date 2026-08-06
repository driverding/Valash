int main() {
    var test = new Variant ("(ss)", "AAA", "BBB");

    message ("%s", test.print (true));

    var c0 = test.get_child_value (0);
    var c1 = test.get_child_value (1);

    message ("%s", c0.print (true));
    message ("%s", c1.print (true));

    return 0;
}
