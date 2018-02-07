module packageversion;

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
