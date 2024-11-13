<!--  -->
<a name="readme-top"></a>
<!---->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

Status:
[![CI](https://github.com/JosifFP/CompositeSystems.jl/workflows/CI/badge.svg)](https://github.com/JosifFP/CompositeSystems.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/JosifFP/CompositeSystems.jl/graph/badge.svg?token=KRVQ19YRIO)](https://codecov.io/gh/JosifFP/CompositeSystems.jl)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2FJosifFP%2FCompositeSystems.jl.svg?type=shield&issueType=license)](https://app.fossa.com/projects/git%2Bgithub.com%2FJosifFP%2FCompositeSystems.jl?ref=badge_shield&issueType=license)
</p>

<!-- PROJECT LOGO -->

<br />
<div align="center">
  <a href="https://github.com/JosifFP/CompositeSystems.jl">
    <img src="docs/images/logo_white.svg" alt="Logo" width="500">
  </a>

<h3 align="center">Generation & Transmission Adequacy Evaluation Tool</h3>

<p align="center">
    <!-- project_description -->
    <br />
    <a href="https://github.com/JosifFP/CompositeSystems.jl"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/JosifFP/CompositeSystems.jl">View Demo</a>
    ·
    <a href="https://github.com/JosifFP/CompositeSystems.jl/issues">Report Bug</a>
    ·
    <a href="https://github.com/JosifFP/CompositeSystems.jl/issues">Request Feature</a>
    ·
    <a href="https://www.mdpi.com/1996-1073/17/20/5023">Article</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Features</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
    <li><a href="#citing">Citing CompositeSystems</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

## About The Project

<!-- [![Product Name Screen Shot][product-screenshot]](https://github.com/JosifFP/CompositeSystems.jl) -->

**[CompositeSystems](https://github.com/JosifFP/CompositeSystems.jl)** is the first open-source Composite System Reliability (CSR) tool written in Julia.
The methodology is based on sequential Monte Carlo sampling of generation and transmission component availability such as: generators, transmission lines,
transformers, shunts, loads and storage systems. Remedial actions, energy storage dispatch and load curtailment are carried out by an efficient linear
programming routine (DC Optimal Power Flow) based on JuMP modeling language and linear solver provided by the user. The program is demonstrated in case
studies with 6-Bus Roy Billiton Test System (RBTS) and the 24-Bus IEEE RTS.

*Powered and inspired by [PowerModels](https://github.com/lanl-ansi/PowerModels.jl) and *NREL's* Probabilistic Resource Adequacy Suite [PRAS](https://github.com/NREL/PRAS)*

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Features

* PTI ".raw" files (PSS(R)E v33 specification) and Matpower ".m" files as input data
* .xls files as time-series input data
* Sequential Monte Carlo Simulation
* DC Optimal Power Flow (polar coordinates)
* Linearized AC Optimal Power Flow (LPAC Approximation, polar coordinates)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

## Getting Started

Installation steps and Quick Start at [https://github.com/JosifFP/CompositeSystems.jl/wiki](https://github.com/JosifFP/CompositeSystems.jl/wiki)

<!-- USAGE EXAMPLES -->

<!-- ## Usage

Soon -->

<!-- CONTRIBUTING -->

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->

## License

[CompositeSystems](https://github.com/JosifFP/CompositeSystems.jl) ©2023 by [Josif Elias Figueroa Parra](https://www.linkedin.com/in/josif-figueroa-parra) is licensed under CC BY-NC-ND 4.0. To view a copy of this license, visit [http://creativecommons.org/licenses/by-nc-nd/4.0/](http://creativecommons.org/licenses/by-nc-nd/4.0/)

<div align="center">
<img src="https://upload.wikimedia.org/wikipedia/commons/5/53/Cc-white.svg" alt="Logo" width="30"><img src="https://upload.wikimedia.org/wikipedia/en/1/11/Cc-by_new_white.svg" alt="Logo" width="30"></a>
</div>

<!-- CONTACT -->

## Contact

Josif Figueroa Parra - [**In**](https://www.linkedin.com/in/josif-figueroa-parra/) - josif.figueroa@unb.ca

Project Link: [https://github.com/JosifFP/CompositeSystems.jl](https://github.com/JosifFP/CompositeSystems.jl)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

This work was supported by MITACS through the Mitacs Accelerate program, Atlantic Canada Opportunities Agency, and Énergie NB Power, NB, Canada, under Grant IT27416.
* Project supervised by Ph.D, P.Eng. Kush Bubbar. https://www.sysmodel.ca/
* Logo designed by Claudio Ferrada IG: @unoilustrado

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!--Citing CompositeSystems -->

## Citing

If you find CompositeSystems useful in your work, we kindly request that you cite the following [publication](https://www.mdpi.com/1996-1073/17/20/5023):
```
@Article{en17205023,
  AUTHOR = {Figueroa, Josif and Bubbar, Kush and Young-Morris, Greg},
  TITLE = {An Open-Source Tool for Composite Power System Reliability Assessment in Julia™},
  JOURNAL = {Energies},
  VOLUME = {17},
  YEAR = {2024},
  NUMBER = {20},
  ARTICLE-NUMBER = {5023},
  URL = {https://www.mdpi.com/1996-1073/17/20/5023},
  ISSN = {1996-1073},
  ABSTRACT = {This paper introduces an open-source tool capable of performing the Composite System Reliability evaluation developed in the high-level, dynamic Julia™ programming language. Employing Monte Carlo Simulation and parallel computing, the tool evaluates probabilistic adequacy indices for combined generation and transmission systems, focusing on both individual delivery points and the broader system. Proficiency in Optimal Power Flow problem formulations is demonstrated through two distinct methods: DC and linearized AC, enabling comprehensive resource and transmission adequacy analysis with high-performance solvers. Addressing replicability and the insufficiency of available software, the tool supports diverse analyses on a unified platform. The paper discusses the tool’s design and validation, particularly focusing on the two optimal power flow problem formulations. These insights significantly contribute to understanding transmission system performance and have implications for power system planning.},
  DOI = {10.3390/en17205023}
}
```
Citation of the work for problem definitions (e.g. OPF): [power flow formulations](https://lanl-ansi.github.io/PowerModels.jl/stable/formulation-details/)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->

<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/JosifFP/CompositeSystems.jl.svg?style=for-the-badge
[contributors-url]: https://github.com/JosifFP/CompositeSystems.jl/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/JosifFP/CompositeSystems.jl.svg?style=for-the-badge
[forks-url]: https://github.com/JosifFP/CompositeSystems.jl/network/members
[stars-shield]: https://img.shields.io/github/stars/JosifFP/CompositeSystems.jl.svg?style=for-the-badge
[stars-url]: https://github.com/JosifFP/CompositeSystems.jl/stargazers
[issues-shield]: https://img.shields.io/github/issues/JosifFP/CompositeSystems.jl.svg?style=for-the-badge
[issues-url]: https://github.com/JosifFP/CompositeSystems.jl/issues
[license-shield]: https://img.shields.io/github/license/JosifFP/CompositeSystems.jl.svg?style=for-the-badge
[license-url]: https://github.com/JosifFP/CompositeSystems.jl/blob/master/LICENSE.md
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/josif-figueroa-parra/
[product-screenshot]: docs/images/logo_white.png
[Next.js]: https://img.shields.io/badge/next.js-000000?style=for-the-badge&logo=nextdotjs&logoColor=white
[Next-url]: https://nextjs.org/
[React.js]: https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB
[React-url]: https://reactjs.org/
[Vue.js]: https://img.shields.io/badge/Vue.js-35495E?style=for-the-badge&logo=vuedotjs&logoColor=4FC08D
[Vue-url]: https://vuejs.org/
[Angular.io]: https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white
[Angular-url]: https://angular.io/
[Svelte.dev]: https://img.shields.io/badge/Svelte-4A4A55?style=for-the-badge&logo=svelte&logoColor=FF3E00
[Svelte-url]: https://svelte.dev/
[Laravel.com]: https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white
[Laravel-url]: https://laravel.com
[Bootstrap.com]: https://img.shields.io/badge/Bootstrap-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white
[Bootstrap-url]: https://getbootstrap.com
[JQuery.com]: https://img.shields.io/badge/jQuery-0769AD?style=for-the-badge&logo=jquery&logoColor=white
[JQuery-url]: https://jquery.com