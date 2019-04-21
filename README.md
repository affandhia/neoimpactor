# NeoImpactor

## What?

So basically is just an automacy script to install all the IPA to your phone.

## Prerequisite

1. OSX installed on your notebook.
1. Cydia Impactor – installed in Application. More info: [http://www.cydiaimpactor.com/](http://www.cydiaimpactor.com/)
1. CliClick – the binary is whether installed or downloaded. More info: [https://github.com/BlueM/cliclick](https://github.com/BlueM/cliclick)
1. SleepDisplay – the binary is whether installed or downloaded. More info: [https://github.com/bigkm/SleepDisplay](https://github.com/bigkm/SleepDisplay)

## How to?

1. run this one `osascript neoimpactor.scpt`
1. at first, it will ask your help to initiate the configuration.
1. let this script working. `NOTE: the script is using virtual click so make sure you enable it in the System Preferences - Accessibility. DON'T move your cursor while the script is working`

## Known Bug & Troubleshoot

1. Using DefaultFolderX cause bug on multiple IPA files. There will be a blink once the script already input the IPA file location. This blink is caused by the reshowing DefaultFolderX. After the blink, the highlighted file will be reverted to the previouse one before the IPA file location input. `SOLUTION:` please exit `Default Folder X` app.
1. Not allowed when running the script. You need to allow the accesibility for your teminal. Latest OSX will ask you to allow acessibility for `Finder` and `System Events`. `SOLUTION:` Just give the accessibility for your beloved terminal and allow all the requested accessibility, you can look at the source code if you need to be convinced.
