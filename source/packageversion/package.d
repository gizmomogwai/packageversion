module packageversion;

string[string] packages;

void registerPackageVersion(string name, string semVer)
{
    packages[name] = semVer;
}

auto getPackages()
{
    return packages;
}
