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
import std.experimental.logger;

void writeContent(string file, string content)
{
    file.dirName.mkdirRecurse;
    std.file.write(file, content);
}

auto getFromDubSdl(string path, string what)
{
    try
    {
        auto pattern = "^%1$s \"(?P<%1$s>.*)\"$".format(what);
        auto text = readText(path);
        auto match = matchFirst(text, regex(pattern, "m"));
        if (match.empty)
        {
            return null;
        }
        return match[what];
    }
    catch (FileException e)
    {
        trace(e);
        return null;
    }
}

auto getFromDubJson(string path, string what)
{
    try
    {
        import std.json;

        auto json = parseJSON(readText(path));
        return json[what].str;
    }
    catch (FileException e)
    {
        trace(e);
        return null;
    }
}

auto packageDir()
{
    import std.process;

    auto e = std.process.environment.toAA;
    if ("DUB_PACKAGE_DIR" !in e)
    {
        return null;
    }
    return e["DUB_PACKAGE_DIR"];
}

auto getFromDubJsonFromPackageDir()
{
    if (string pd = packageDir)
    {
        return getFromDubJson(pd ~ "/dub.json", "version");
    }
    return null;
}

string getFromDubSdlFromPackageDir()
{
    if (string pd = packageDir)
    {
        return getFromDubSdl(pd ~ "/dub.sdl", "version");
    }
    return null;
}

string getFromGit()
{
    auto gitCommand = ["git", "describe", "--dirty"].execute(null, Config.none,
            size_t.max, packageDir);
    if (gitCommand.status != 0)
    {
        "Cannot get version with git describe --dirty, make sure you have at least one annotated tag"
            .info;
        return null;
    }

    return gitCommand.output.strip;
}

string getVersion()
{
    if (string res = getFromDubJsonFromPackageDir)
    {
        "Using version from dub.json '%s'".format(res).warning;
        return res;
    }
    if (string res = getFromDubSdlFromPackageDir)
    {
        "Using version from dub.sdl '%s'".format(res).warning;
        return res;
    }
    if (string res = getFromGit)
    {
        "Using version from git '%s'".format(res).warning;
        return res;
    }
    throw new Exception("Cannot determine version");
}

int main(string[] args)
{
    import std.getopt;

    string packageName;
    auto info = getopt(args, "packageName", &packageName);
    if (info.helpWanted)
    {
        defaultGetoptPrinter("packageversion %s. Generate or update a simple packageversion module.".format("v0.0.12"),
                info.options);
        return 0;
    }
    if (packageName == null)
    {
        defaultGetoptPrinter("Packagename required.", info.options);
        return 1;
    }

    auto versionText = getVersion();

    auto file = "out/generated/packageversion/" ~ packageName.replace(".",
            "/") ~ "/packageversion.d";
    auto moduleText = "module %s.packageversion;\n".format(packageName);
    auto packageVersionText = "const PACKAGE_VERSION = \"%s\";\n".format(versionText);
    auto registerVersionText = "static this()\n{\n    import packageversion;\n    packageversion.registerPackageVersion(\"%s\", \"%s\");\n}\n"
        .format(packageName, versionText);
    auto totalText = moduleText ~ packageVersionText ~ registerVersionText;

    if (exists(file))
    {
        auto content = file.readText;
        if (content != totalText)
        {
            "Updating packageversion module".warning;
            file.writeContent(totalText);
        }
    }
    else
    {
        "Writing packageversion module".warning;
        file.writeContent(totalText);
    }
    return 0;
}
