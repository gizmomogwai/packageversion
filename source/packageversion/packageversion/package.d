module packageversion.packageversion;
import packageversion;
const VERSION = "0.0.15";
const LICENSE = "MIT";
const NAME = "packageversion";
static this()
{
    registerPackageVersion(NAME, VERSION, LICENSE);
}
