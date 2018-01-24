import std.stdio;
import std.string;

int main(string[] args)
{
    import std.getopt;

    string packageName;
    auto info = getopt(args, "packageName", &packageName);
    if (info.helpWanted)
    {
        import packageversion;
        defaultGetoptPrinter("packageversion %s. Generates a simple packageversion module.".format(packageversion.packageVersion), info.options);
        return 0;
    }
    if (packageName == null)
    {
        defaultGetoptPrinter("Packagename required.", info.options);
        return 1;
    }

    import std.process;

    auto gitVersion = ["git", "describe"].execute.output.strip;

    import std.file;

    auto fileName = "source/" ~ packageName.replace(".", "/") ~ "/packageversion.d";

    import std.path;

    auto directory = dirName(fileName);
    writeln("directory: ", directory);
    mkdirRecurse(directory);
    std.file.write(fileName, "module %s;
auto packageVersion = \"%s\";
".format(packageName, gitVersion));

    return 0;
}
