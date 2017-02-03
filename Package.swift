import PackageDescription

let package = Package(
    name: "WhiteWidow",
    dependencies: [
        .Package(url: "https://github.com/tid-kijyun/Kanna.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/fluent.git", majorVersion: 1, minor: 3),
		.Package(url: "https://github.com/vapor/postgresql-driver.git", majorVersion: 1)
    ]
)
