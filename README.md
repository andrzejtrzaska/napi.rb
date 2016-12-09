# Napi

Portable NapiProjekt client written in ruby.

## Requirements

Make sure to have ruby installed on your system. That's it.

## Installation

    wget https://raw.githubusercontent.com/andrzejtrzaska/napi.rb/master/napi
    chmod +x napi

## Usage

The usage is very simple. Just pass a directory or a movie path as a argument to napi script. It will download all possible subtitles instantly.

    ./napi ~/Videos

By default, API V3 is used.

You can enable legacy V1 support by setting NAPIPROJEKT_API_VERSION environment variable, like so:

    NAPIPROJEKT_API_VERSION=1 ./napi ~/Videos

You can change subtitles language using NAPIPROJEKT_LANGUAGE environment variable:

    NAPIPROJEKT_LANGUAGE=ENG ./napi ~/Videos

By default, polish is used.

## Notes

When using NapiProjekt API V1, by default ```windows-1250``` character encoding is assumed. Subtitles are automatically converted to ```utf-8```.
In case conversion is not possible, subtitles will have original character encoding.

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## History

v0.3 - Change default api to v3, get rid of 7z dependency, add language environment variable for manipulating language of subtitles

v0.2 - Fix small bug in api v1 f function, add multithreaded downloading of subtitles

v0.1 - Implement NapiProjekt API v1 and v3

## Credits

[Andrzej Trzaska](https://github.com/andrzejtrzaska)

## License

MIT Licensed. Copyright (c) Andrzej Trzaska 2016.
