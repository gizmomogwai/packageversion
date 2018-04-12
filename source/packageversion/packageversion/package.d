/++
 + Copyright: Copyright © 2018, Christian Köstlin
 + License: MIT
 + Authors: Christian Koestlin
 +/

module packageversion.packageversion;
import packageversion;

const VERSION = "0.0.17";
const LICENSE = "MIT";
const NAME = "packageversion";
static this()
{
    registerPackageVersion(NAME, VERSION, LICENSE);
}
