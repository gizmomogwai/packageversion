/++
 + Copyright: Copyright © 2018, Christian Köstlin
 + License: MIT
 + Authors: Christian Koestlin
 +/

module packageversion;

@safe:

public import packageversion.packageversion;

Package[] packages;

struct Package
{
    string name;
    string semVer;
    string license;
}

void registerPackageVersion(string name, string semVer, string license)
{
    packages ~= Package(name, semVer, license);
}

auto getPackages()
{
    return packages;
}
