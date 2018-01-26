/++
 + Copyright: Copyright © 2018, Christian Köstlin
 + License: MIT
 + Authors: Christian Koestlin
 +/
module app;

import std.stdio;
import std.string;
import std.process;
import std.file;
import std.path;
import std.file;
import std.regex;

void writeContent(string file, string content)
{
    file.dirName.mkdirRecurse;
    std.file.write(file, content);
}

int main(string[] args)
{
    import std.getopt;

    string packageName;
    auto info = getopt(args, "packageName", &packageName);
    if (info.helpWanted)
    {
        defaultGetoptPrinter("packageversion %s. Generate or update a simple packageversion module.".format("v0.0.10"),
                info.options);
        return 0;
    }
    if (packageName == null)
    {
        defaultGetoptPrinter("Packagename required.", info.options);
        return 1;
    }

    auto gitCommand = ["git", "describe", "--dirty"].execute;
    if (gitCommand.status != 0)
    {
        throw new Exception(
                "Cannot get version with git describe --dirty, make sure you have at least one annotated tag");
    }

    auto gitVersion = gitCommand.output.strip;

    auto file = "out/generated/packageversion/" ~ packageName.replace(".",
            "/") ~ "/packageversion.d";
    auto moduleText = "module %s.packageversion;\n".format(packageName);
    auto packageVersionText = "const PACKAGE_VERSION = \"%s\";\n".format(gitVersion);
    auto totalText = moduleText ~ packageVersionText;

    if (exists(file))
    {
        auto content = file.readText;
        auto replaceVersionRegexp = regex("^const PACKAGE_VERSION = \"(.*)\";$", "m");
        if (!matchFirst(content, replaceVersionRegexp).empty)
        {
            auto newContent = content.replaceFirst(replaceVersionRegexp, packageVersionText);
            if (newContent != content)
            {
                "Updating packageversion module.".writeln;
                file.writeContent(newContent);
            }
            else
            {
                "packageversion module already up to date.".writeln;
            }
        }
        else
        {
            "Adding packageversion to existing module.".writeln;
            file.writeContent(content ~ packageVersionText);
        }
    }
    else
    {
        "Adding packageversion module to project.".writeln;
        file.writeContent(totalText);
    }
    return 0;
}
