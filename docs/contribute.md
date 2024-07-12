# How to Contribute?

## Issues

* If you encounter any challenges or problems with the script, I kindly request that you submit them via the "Issues" tab on the GitHub repository. By filling out the provided template, you can provide specific details about the issue, allowing me (and others in the community) to promptly address any bugs, or consider feature requests.

## Contribute Code

* Pull Requests are now handled directly on the **MAIN branch**. This was done since we can now select specific releases to launch via releases in GitHub.

* If you're doing code changes, then you can submit a PR to `main` branch, but I am very selective about these.

> [!WARNING]
> Do not use a code formatter, massive amounts of line changes, and make multiple feature changes.
> EACH FEATURE CHANGE SHOULD BE IT'S OWN Pull Request!

* When creating pull requests, it is essential to thoroughly document all changes made. This includes, but not limited to, documenting any additions made to the `tweaks` section and corresponding `undo tweak`, so users are able to remove the newly added tweaks if necessary, and comprehensive documentation is required for all code changes, document your changes and briefly explain why you made your changes in your Pull Request Description. Failure to adhere to this format may result in denial of the pull request. Additionally, Any code lacking sufficient documentation may also be denied.

* By following these guidelines, we can maintain a high standard of quality and ensure that the codebase remains organized and well-documented.

> [!NOTE]
> When creating a function, please include "WPF" or "WinUtil" in the file name so it can be loaded into the runspace.

## Walk through

### Fork the Repo
* Fork the WinUtil Repository [here](https://github.com/ChrisTitusTech/winutil) to create a copy that will be available in your Repository-list.
![Fork](assets/ForkButton.png)

### Modify the Fork
* While you can make your changes directly through the Web, we recommend cloning the repo to your device to test your fork easily. 
#### GitHub Desktop
* Using the application GitHub Desktop (available in WinUtil) you can easily manage your repos locally.
1. Install GitHub Desktop if not already installed
2. Log in using the same GitHub account u used to fork WinUtil
3. Choose the fork under "Your Repositories" and press "clone {repo name}"

* Now you can modify WinUtil to your liking using your prefered text editor.

#### git
1. Install Git (available in WinUtil) if not already installed.
2. Open a terminal or command prompt.
3. change the directory to where the fork should be cloned:
4. Clone your forked repository using the following command:
* git clone https://github.com/{your-username}/winutil.git
5. you can now find

### Testing your changes
* To test to see if your changes work as intended run following commands in a powershell teminal:

* Change the directory where you are running the commands to the forked project.
* `cd {path to the folder with the compile.ps1}`
* Run following command to compile and run Winutil
* `.\Compile.ps1 -run`
* After seeing that your changes work properly feel free to commit the changes to the repository and make a PR, for help on that follow the documentation below.

### Commiting the changes
#### Github Desktop
* 

### Making a PR
* To make a PR on your repo under a new branch linking to the main branch a button will show and say Preview and Create pull request. Click that button and fill in all information that is provided on the template. Once all the information is filled in correctly check your PR to make sure there is not a WinUtil.ps1 file attached to the PR. Once everything is good make the PR and wait for Chris (The Maintainer) to accept or deny your PR. Once it is accepted in by Chris you will be able to see your changes in the /windev build.
* If you do not see your feature in the main /win build that is fine. As all new changes go into the /windev build to make sure everything is working ok before going fully public.
* Congrats you just submitted your first PR. Thank you so much for contributing to WinUtil.