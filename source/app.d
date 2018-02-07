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
        return null;
    }
}

auto getFromDubJson(string path, string what)
{
    try
    {
        import std.json;

        return parseJSON(readText(path))[what].str;
    }
    catch (FileException e)
    {
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

auto getFromDubJsonFromPackageDir(string what)
{
    if (string pd = packageDir)
    {
        return getFromDubJson(pd ~ "/dub.json", what);
    }
    return null;
}

string getFromDubSdlFromPackageDir(string what)
{
    if (string pd = packageDir)
    {
        return getFromDubSdl(pd ~ "/dub.sdl", what);
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

string getLicense()
{
    auto what = "license";
    if (string res = getFromDubJsonFromPackageDir(what))
    {
        "Using %s from dub.json '%s'".format(what, res).warning;
        return res;
    }
    if (string res = getFromDubSdlFromPackageDir(what))
    {
        "Using %s from dub.sdl '%s'".format(what, res).warning;
        return res;
    }
    throw new Exception("Cannot determine %s".format(what));

}

string getVersion()
{
    auto what = "version";
    if (string res = getFromDubJsonFromPackageDir(what))
    {
        "Using %s from dub.json '%s'".format(what, res).warning;
        return res;
    }
    if (string res = getFromDubSdlFromPackageDir(what))
    {
        "Using %s from dub.sdl '%s'".format(what, res).warning;
        return res;
    }
    if (string res = getFromGit)
    {
        "Using %s from git '%s'".format(what, res).warning;
        return res;
    }
    throw new Exception("Cannot determine %s".format(what));
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
    auto license = getLicense();
    auto file = "out/generated/packageversion/" ~ packageName.replace(".",
            "/") ~ "/packageversion.d";
    auto moduleText = "module %s.packageversion;\n".format(packageName);
    auto packageVersionText = "const PACKAGE_VERSION = \"%s\";\n".format(versionText);
    auto registerVersionText = "static this()\n{\n    import packageversion;\n    packageversion.registerPackageVersion(\"%s\", \"%s\", \"%s\");\n}\n"
        .format(packageName, versionText, license);
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
