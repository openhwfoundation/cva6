# Contributing
New Contributors are always welcome.

Note that Contributors are required to be covered by an [Eclipse Contributor Agreement](https://www.eclipse.org/legal/ECA.php).
Contributors are encouraged, but not required, to be a [member](https://openhwfoundation.org/become-a-member/)) of the OpenHW Foundation.

## Read this before

### Major evolutions

CVA6 has turned into an industrial project, where the core is being verified to be integrated in production ICs.
In the same time, we'd like to continue integrating some new contributions to keep CVA6 a vivid and innovative ecosystem.
But this comes with constraints to ensure that new contributions do not put the industrial project at risk.

Therefore here are guidelines to help the CVA6 team accept new contributions:

- Get in touch early with the CVA6 team, present your initiative, get feedback, synchronize with the team...
    * The CVA6 team wants to assess the potential of your contribution.
    * The CVA6 team can provide you recommendations to ease the upcoming contribution.
    * This can help save significant review and overhauling effort for you and us when dealing with the pull request review.
    * Together, we can anticipate specific cases that are not addressed here.
    * If you do not know how to contact us already, you can get in touch through the [OpenHW contact page](https://openhwfoundation.org/contact/) or open an issue in GitHub.

- Specific recommendations:
    * Always consider using the CV-X-IF interface if your contribution is an instruction-set extension.
        - and talk to the team if it's not possible.
    * Your contribution shall be optional and fully disabled by default.
        - so that projects already using CVA6 are not impacted (no functionality change, no extra silicon...).
    * To configure your contribution, System Verilog top-level parameters are preferred.
        - Synchronize with CVA6 team if this is not possible and you need other means (`directives, ariane_pkg parameters, templating...)
        - Synchronize with CVA6 team (again) because this rule is likely to change over time as we are considering templating.
    * Commit to maintain your contribution 2 years after the pull request
        - We know it's not always possible, so refer to the next rule.
    * Your complete contribution shall be identifiable with parameters (or `directives / templating if together we decide to go this way).
        - If at some point we need to revert it, e.g. if there is no-one maintaining nor using it and it has become a burden to the project.
        - We call this the "parachute" rule: The CVA6 team does not want to use it but is far more comfortable getting one.
    * Your contribution shall pass the Continuous Integration (CI) flow
        - When the contribution is disabled: in all cases, to ensure you have not broken the design.
        - When the contribution is disabled: the line and condition code coverage shall not be impacted.
        - When the contribution is enabled: in relevant cases.
        - You can issue a "do not merge" pull request to test your contribution.
        - RTL code located in `core` directory is formatted with `verible-verilog-format`. See [Verible command to be executed](#verible).
    * Your contribution shall come with its own regression test to integrate in the CI flow.
        - So that we can detect quickly if future updates break your contribution.
        - To avoid impacting those users who use your contribution in their project.
        - At this point, we do not request a 100%-coverage verification suite.

If you encounter difficulties with these guidelines, get in touch with the team!

### Copyright and license headers

Although the repository includes a [LICENSE](https://github.com/openhwfoundation/cva6/blob/master/LICENSE) file,
it is essential to include appropriate copyright and license headers in individual files, as they can be copied and used outside of the repository context.

When contributing, please adhere to these rules:
- **Add headers**: Include a copyright and license header in all new files, as well as in updated files that currently lack one.
- **Do not alter licenses**: Never change an existing license (for instance, changing Solderpad 0.51 to another license).
- **Preserve copyright history**: Do not remove or replace existing copyright owners. 
- You may add additional copyright owners (typically your company or university) when you contribute significant changes, such as a major feature or a substantial performance increase.
- In the copyright line, specify the year when the copyright was added with the `20xx` format. Do not update this year for subsequent modifications.

Note: The copyright owner of your work is legally your employer or university in most contexts.

Here is a Solderpad 0.51 file header, wrapped to 100 characters according to lowRISC SystemVerilog coding style:

```
// Copyright [year] [name of copyright owner]
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51
// (the "License"); you may not use this file except in compliance with the License.
// You may obtain a copy of the License at http://solderpad.org/licenses/SHL-0.51.
// Unless required by applicable law or agreed to in writing, software, hardware and materials
// distributed under this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//
// Contributors:
//   [name of the author], [their organisation] - Original Author
```

For files governed by other licenses, you should refer to the headers recommended by the respective license promoters. Ensure that an `SPDX-License-Identifier` is included for automated parsers.

Detailed information about intellectual property and headers can be found in the [Eclipse Foundation Project Handbook](https://www.eclipse.org/projects/handbook/#ip-copyright-headers).

If you have questions about licenses and headers, get in touch with the project team!

### Bug fixing

Bug fixing is always welcome. You can issue a GitHub issue. Better: solve the bug and trigger a pull request.

## The Mechanics
1. From GitHub: [fork](https://help.github.com/articles/fork-a-repo/) the [cva6](https://github.com/openhwfoundation/cva6) repository
2. Clone repository: `git clone https://github.com/[your_github_username]/cva6`
3. Create your feature branch: `git checkout -b <my_branch>.`<br> Please uniquify your branch name.
See the [Git Cheats](https://github.com/openhwfoundation/core-v-verif/blob/master/GitCheats.md) for a useful nomenclature.
4. Make your edits...
5. Commit your changes: `git commit -m 'Add some feature'`
6. Push feature branch: `git push origin <my_branch>`
7. From GitHub: submit a pull request

Please note that we do not accept outdated pull requests.
This makes sure the CI flow has run in the to-be version of the master.

To allow us to update the pull request before merging it, please consider checking the "Allow edits from maintainers" checkbox.
Note that this can only be done with pull requests from your personal repository (it is impossible from organization repositories).

## Coding Style

For RTL coding, the OpenHW Foundation has adopted the [lowRISC Style Guides](https://github.com/lowRISC/style-guides/).

## Git Considerations

- Do not push to master, if you want to add a feature do it in your branch.
- Separate subject from body with a blank line.
- Limit the subject line to 50 characters.
- Capitalize the subject line.
- Do not end the subject line with a period.
- Use the imperative mood in the subject line.
- Use the present tense ("Add feature" not "Added feature").
- Wrap the body at 72 characters.
- Use the body to explain what and why vs. how.
- Select relevant GitHub labels (e.g. ``Component:Doc``, ``Type:Bug``...)

For a detailed why and how please refer to one of the multiple [resources](https://chris.beams.io/posts/git-commit/) regarding git commit messages.

If you use `vi` for your commit message, consider to put the following snippet inside your `~/.vimrc`:

```
autocmd Filetype gitcommit setlocal spell textwidth=72s
```

## Verible

To format RTL files checked by GitHub , use the following command:

```
verible-verilog-format --inplace $(git ls-tree -r HEAD --name-only core |grep '\.sv$' |grep -v '^core/include/std_cache_pkg.sv$' |grep -v cvfpu)
```
