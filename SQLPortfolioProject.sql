
/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select * 
From PortfolioProject..CovidDeathsTable
order by 3,4

-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeathsTable
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths 
-- Also shows death percentage

Select Location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage
From PortfolioProject..CovidDeathsTable
order by 1,2

-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage
From PortfolioProject..CovidDeathsTable
Where location like '%India%'
and continent is not null 
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases, (convert(float,total_cases)/NULLIF(Convert(float,population),0))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeathsTable
--Where location like '%states%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((convert(float,total_cases)/NULLIF(Convert(float,population),0)))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeathsTable
--Where location like '%states%'
Group by Location, Population
order by 1,2


Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((convert(float,total_cases)/NULLIF(Convert(float,population),0)))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeathsTable
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeathsTable
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeathsTable
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS

Select SUM(convert(int,new_cases)) as total_cases, SUM(convert(int,new_deaths)) as total_deaths,
SUM(convert(int,new_deaths))/nullif(SUM(convert(int,New_Cases)),0)*100 as DeathPercentage
From PortfolioProject..CovidDeathsTable
where continent is not null 
order by 1,2


Select * 
From PortfolioProject..CovidVaccinationsTable
order by 3,4

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select d.continent, d.location,d.date,d.population,v.new_vaccinations,
sum(convert(int,v.new_vaccinations)) over (Partition by d.location order by d.location,d.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeathsTable d
Join PortfolioProject..CovidVaccinationsTable v
     on d.location = v.location
	 and d.date = v.date
where d.continent is not null
order by v.new_vaccinations desc


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.location Order by d.location,d.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeathsTable d
Join PortfolioProject..CovidVaccinationsTable v
     On d.location = v.location
	 and d.date = v.date
	 where d.continent is not null
	  and d.location = '%Austria%'
	 )
Select *, (RollingPeopleVaccinated/nullif(Population,0))*100
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query


DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(cast(v.new_vaccinations as int )) OVER (Partition by d.location Order by d.location,d.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeathsTable d
Join PortfolioProject..CovidVaccinationsTable v
     On d.location = v.location
	 and d.date = v.date
	 

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as 
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int, v.new_vaccinations)) OVER (Partition by d.location Order by d.location, d.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeathsTable d
Join PortfolioProject..CovidVaccinationsTable v
     On d.location = v.location
	 and d.date = v.date
where d.continent is not null
