# Contributing

New motivated Contributors are always welcome.

Note that Contributors are required to be covered by an [Eclipse Contributor Agreement](https://www.eclipse.org/legal/ECA.php).
If a pull request has been open with no ECA for more than 24 hours, we consider it as either an automated pull request, which is not allowed, or an unmotivated pull request, which is rejected.
Such pull requests will be closed by maintainers.
So, if you encounter any issues, with the signing process, please tell us!
We will be glad to help.
Drop a comment in your pull request so we know about your problem and we do not close your pull request.

Contributors are encouraged, but not required, to be a [member](https://openhwfoundation.org/membership/become-a-member/) of the OpenHW Foundation, part of the Eclipse Foundation.

## Read this first

### Major evolutions

CVA6 has turned into an industrial project, where the core is being verified to be integrated in production ICs.
At the same time, we'd like to continue integrating some new contributions to keep CVA6 a vivid and innovative ecosystem.
This comes with constraints to ensure that new contributions do not put the industrial project at risk.

Past experience indicates that a workplan shared early with the CVA6 project team and regular synchronization improves the project's ability to integrate major contributions.
Early discussions with the CVA6 team will help us to develop a strategy to integrate your contribution onto a specific development branch, with the goal of upstreaming to the master branch.
Here are some guidelines to help the CVA6 team accept new contributions of major features:

- Get in touch early with the CVA6 team, present your initiative, get feedback, synchronize with the team...
    * The CVA6 team wants to assess the potential of your contribution.
    * The CVA6 team plans the next evolutions, and your contributions could be incompatible with them.
    * The CVA6 team can provide you recommendations to ease the upcoming contribution.
    * This can help save significant review and overhauling effort for you and us when dealing with the pull request review.
    * Together, we can anticipate specific cases that are not addressed here.
    * If you do not know how to contact us already, get in touch through info@eclipse-foundation.org or open an issue in GitHub.

- Specific recommendations:
    * For instruction set extensions, talk to the team to assess the relevance of including it into the core or as a coprocessor on the CV-X-IF interface.
        -  If the extension is custom (not a RISC-V specified extension), a coprocessor on CV-X-IF is definitely its place.
    * Your contribution shall be optional and fully disabled by default.
        - so that projects already using CVA6 are not impacted (no functionality change, no extra silicon...).
    * To configure your contribution, System Verilog top-level parameters are strongly advised.
        - Conditional compiler directives such as <code>`ifdef</code>, etc. are strongly discouraged.
        - Please review our wiki on the topic of [Configuring SystemVerilog RTL Models](https://github.com/openhwgroup/cva6/wiki/Configuring-SystemVerilog-RTL-Models), in particular the [CVA6 use case](https://github.com/openhwgroup/cva6/wiki/Configuring-SystemVerilog-RTL-Models#use-case-the-openhw-foundation-cva6).
        - Synchronize with CVA6 team if you do not find an appropriate solution.
    * Commit to maintain your contribution 2 years after the pull request
        - We know it's not always possible, so refer to the next rule.
    * Your complete contribution shall be identifiable with parameters.
        - If at some point we need to revert it, e.g. if there is no-one maintaining nor using it and it has become a burden to the project.
        - We call this the "parachute" rule: The CVA6 team does not want to use it but is far more comfortable getting one.
        - Also, this allows not to lose code coverage in verification when your contribution is not enabled (with some tweaks in the coverage tool).
        - This rule also applies to CSRs which are specific to your contribution.
    * To ease maintenance, all common code lines shall exist only once.
        - Counter-example: CVA6 used to have two different MMU modules (Sv32 and Sv39) for CV32A6 and CV64A6. It took time to refactor both in a joint design to ease maintenance.
        - Related reading for reference: [DRY principle](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
    * Your contribution shall pass the Continuous Integration (CI) flow
        - When the contribution is disabled: in all cases, to ensure you have not broken the design.
        - When the contribution is disabled: the line and condition code coverage shall not be impacted.
        - When the contribution is enabled: in relevant cases.
        - You can issue a "do not merge" pull request to test your contribution.
        - Before you open the pull request, run at least the open-source regression, on every target. It needs no licence and no FPGA board:
          ```
          ./cook.py full-regression --open-source -j 16
          ```
          It checks the formatting (Verible, Black, Pylint), the lint (slang and Verilator) and the Yosys synthesis of every target, runs hello-world on the Verilator TestHarness, and builds the documentation. The result is in `artifacts/reports/pipeline_report.html`.
        - If you have the commercial tools (VCS, Spyglass, Design Compiler, Vivado), run the full regression instead: `./cook.py full-regression -j 16`. See [tutorials/developer/ci_checks.md](tutorials/developer/ci_checks.md).
        - RTL code located in `core` directory is formatted with `verible-verilog-format`. See [Verible command to be executed](#verible).
    * Your contribution shall come with its own regression test to integrate in the CI flow.
        - So that we can detect quickly if future updates break your contribution.
        - To avoid impacting those users who use your contribution in their project.
        - At this point, we do not request a 100%-coverage verification suite.
    * Please consider adding related documentation in the user's guide and design document.
    * Be kind to the people who process your pull request(s)
        - Explain your contribution in the pull request.
        - If your contribution solves an issue, fill in an issue and cross link it in the pull-request.
        - The reviewer(s) prefer to review several small pull requests rather one large pull request. Synchronize with the team to identify the right breakdown.

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

Bug fixing is always welcome. You can open a GitHub issue.
Better: in addition to the issue, solve the bug and trigger a pull request.
Ideally, your pull request will include a testcase that illustrates the bug.

### Use of AI

We understand that some developers are assisted by large language models to help write code. However, AI-generated code shall always be reviewed and endorsed **by the human contributor** before submitting the pull request.
The review by the human contributor shall be as thorough as if they had written the code themselves. Notably the human contributor shall understand and explain all generated code and assess the relevance of comments.

Contributions through code/documentation (pull requests) or feedback (issues) are highly appreciated, but keep in mind that each contribution has a cost for the project, as reviewers will spend time discussing the contributions.
For more information on this topic, see: <https://llvm.org/docs/AIToolPolicy.html#extractive-contributions>

This is why **automated pull requests, directly generated by large language models or AI coding assistants, are not permitted in this repository**.
Such contributions will be closed without review.

Also, note that the review process implies discussing the contribution between the reviewers and the author.
We consider that it would be particularly rude if the author lets an AI answer instead of answering themselves.
We are not expecting long answers with a perfect English. We are expecting *the author's* thoughts on a specific topic.

## The Mechanics
1. From GitHub: [fork](https://help.github.com/articles/fork-a-repo/) the [cva6](https://github.com/openhwgroup/cva6) repository
2. Clone repository: `git clone https://github.com/[your_github_username]/cva6`
3. Create your feature branch: `git checkout -b <my_branch>.`<br> Please uniquify your branch name.
See the [Git Cheats](https://github.com/openhwgroup/core-v-verif/blob/master/GitCheats.md) for a useful nomenclature.
4. Make your edits...
5. Commit your changes: `git commit -m 'Add some feature'`
6. Push feature branch: `git push origin <my_branch>`
7. From GitHub: submit a pull request. The description must tell the reviewers why these changes are important for the project. More advice is provided in the pull request template.

Please note that we do not accept outdated pull requests.
This makes sure the CI flow has run in the to-be version of the master.

To allow us to update the pull request before merging it, please consider checking the "Allow edits from maintainers" checkbox.
Note that this can only be done with pull requests from your personal repository (it is impossible from organization repositories).

One last note: use the same email address for your GitHub and Eclipse accounts, to ensure a smooth Eclipse Contributor Agreement
check for your pull request.

## Coding Style

For RTL coding, the OpenHW Foundation has adopted the [lowRISC Style Guides](https://github.com/lowRISC/style-guides/).

## Git Considerations

- The pull request must be rebased on the master branch to be merged on GitHub. That is why we are requesting permissions on the PR branch to allow the committer to perform the rebasing.
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

To format the RTL files of a target, use the following command:

```
./cook.py verible-rtl-formating -t <target>
```

The GitHub CI checks all the SystemVerilog files under `core/` except the generated configuration packages:

```
verible-verilog-format --inplace $(git ls-tree -r HEAD --name-only core |grep '\.sv$' |grep -v '^core/include/.*_config_pkg\.sv$')
```

The Verible version currently used in the GitHub CI worflow can be found in [`.github/workflows/verible.yml`](.github/workflows/verible.yml).
