<!--  -->
<a name="readme-top"></a>
<!---->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->

<br />
<div align="center">
  <a href="https://github.com/JosifFP/CompositeSystems.jl">
    <img src="docs/images/logo_white.png" alt="Logo" width="320" height="160">
  </a>

<h3 align="center">Composite System Reliability Evaluation Tool</h3>

<p align="center">
    project_description
    <br />
    <a href="https://github.com/JosifFP/CompositeSystems.jl"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/JosifFP/CompositeSystems.jl">View Demo</a>
    ·
    <a href="https://github.com/JosifFP/CompositeSystems.jl/issues">Report Bug</a>
    ·
    <a href="https://github.com/JosifFP/CompositeSystems.jl/issues">Request Feature</a>
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
      <ul>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

## About The Project

[![Product Name Screen Shot][product-screenshot]](https://github.com/JosifFP/CompositeSystems.jl)

CompositeSystems.jl is the first open-source Composite System Reliability (CSR) tool written in Julia. The methodology is based on sequential Monte Carlo sampling of generation and transmission component availability such as: generators, transmission lines, transformers, shunts, loads and storage systems. Remedial actions, energy storage dispatch and load curtailment are carried out by an efficient linear programming routine (DC Optimal Power Flow) based on JuMP modeling language and linear solver provided by the user. The program is demonstrated in case studies with 6-Bus Roy Billiton Test System (RBTS) and the 24-Bus IEEE RTS.

**Powered and inspired by [PowerModels](https://github.com/lanl-ansi/PowerModels.jl) and *NREL's* Probabilistic Resource Adequacy Suite [PRAS](https://github.com/NREL/PRAS)**

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

Soon

### Installation

1. Get a free gurobi licence at [https://www.gurobi.com/academia/academic-program-and-licenses/](https://www.gurobi.com/academia/academic-program-and-licenses/)
2. Clone the repo

   ```sh
   git clone https://github.com/JosifFP/CompositeSystems.jl.git
   ```
3. Install dependent packages and Gurobi license
4. Run runtests.jl

<!-- USAGE EXAMPLES -->

## Usage

Soon

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

Distributed under the MIT License. See `LICENSE.txt` for more information.

<!-- CONTACT -->

## Contact

Josif Figueroa Parra - [**In**](https://www.linkedin.com/in/josif-figueroa-parra/) - josif.figueroa@gmail.com

Project Link: [https://github.com/JosifFP/CompositeSystems.jl](https://github.com/JosifFP/CompositeSystems.jl)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

This work was supported by MITACS through the Mitacs Accelerate program, Atlantic Canada Opportunities Agency, and Énergie NB Power, NB, Canada, under Grant IT27416.

The primary developer is Josif Figueroa (@JosifFP) with support of the following contributors:

* [Dr. Kush Bubbar](https://www.unb.ca/faculty-staff/directory/j-herbert-smith-centre-tme/bubbar-kush.html)
* [M.S. Greg Young-Morris](https://www.linkedin.com/in/greg-young-morris-4114a426/)
* [Sys-MoDEL Lab](https://github.com/sysmodel)

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
[license-url]: https://github.com/JosifFP/CompositeSystems.jl/blob/master/LICENSE.txt
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
