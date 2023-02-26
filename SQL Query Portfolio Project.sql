Select *
From Portfolio.dbo.CovidDeaths
order by 3,4

--Select *
--From Portfolio.dbo.CovidVax
--order by 3,4

-- select data that we are going to be using

Select 
	Location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
From Portfolio.dbo.CovidDeaths
order by 1,2

-- looking at the total cases vs total deaths

Select 
	Location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 as Deathpercentage
From Portfolio.dbo.CovidDeaths
order by 1,2

-- looking death percentage in canada
-- shows the likelihood of dying if you contract covid in canada
Select 
	Location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 as Deathpercentage
From Portfolio.dbo.CovidDeaths
where location like '%canada%'
order by 1,2

-- looking at total cases vs population
-- shows what % of population got covid
Select 
	Location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 as PercentPopulationInfected
From Portfolio.dbo.CovidDeaths
where location like '%canada%'
order by 1,2

-- what countries have the highest infection rate?
-- looking at countries with highest infection rate vs population

Select 
	Location,
	population,
	max(total_cases) as HighestInfectionCount,
	max((total_cases/population))*100 as PercentPopulationInfected
From Portfolio.dbo.CovidDeaths
group by location, population
order by  PercentPopulationInfected desc

-- showing the countries with highest death count per population

Select 
	Location,
	population,
	max(total_deaths) as TotalDeathCount
From Portfolio.dbo.CovidDeaths
group by location, population
order by  TotalDeathCount desc

-- the outcome of above query does not grouped the data desc because the type of data is nvarchar instead of int
-- so we need to change it to int

Select 
	Location,
	population,
	max(cast(total_deaths as int)) as TotalDeathCount
From Portfolio.dbo.CovidDeaths
group by location, population
order by  TotalDeathCount desc

-- the outcome of above query also included continent. we only need countries
-- so we need to include only countries and exclude continent

Select 
	Location,
	population,
	max(cast(total_deaths as int)) as TotalDeathCount
From Portfolio.dbo.CovidDeaths
where continent is not null
group by location, population
order by  TotalDeathCount desc

Select 
	Location,
	population,
	max(cast(total_deaths as int)) as TotalDeathCount,
	max((total_deaths/population))*100 as PercentPopulationDeath
From Portfolio.dbo.CovidDeaths
where continent is not null
group by location, population
order by  PercentPopulationDeath desc

-- let's break things down by continent

Select 
	continent,
	max(cast(total_deaths as int)) as TotalDeathCount
From Portfolio.dbo.CovidDeaths
where continent is not null
group by continent
order by  TotalDeathCount desc

-- the output isn't accurate as north america does not include canada
-- so we need to use location instead

Select 
	location,
	max(cast(total_deaths as int)) as TotalDeathCount
From Portfolio.dbo.CovidDeaths
where continent is null
group by location
order by  TotalDeathCount desc

-- Breaking global numbers per day

Select 
	date,
	sum(new_cases) as total_cases,
	sum(cast(new_deaths as int)) as total_deaths,
	sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
From Portfolio.dbo.CovidDeaths
where continent is not null
group by date
order by  1,2

-- overall figures

Select 
	sum(new_cases) as total_cases,
	sum(cast(new_deaths as int)) as total_deaths,
	sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
From Portfolio.dbo.CovidDeaths
where continent is not null
-- group by date
order by  1,2

-- COVID VAX TABLE

Select *
from Portfolio.dbo.CovidVax

-- join the 2 tables

Select *
from Portfolio.dbo.CovidDeaths dea
join Portfolio.dbo.CovidVax vax
	on dea.location = vax.location
	and dea.date = vax.date

-- Looking at total population vs vaccinations
-- how to add rolling number per date
-- how many people in the countries have been vaccinated

Select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vax.new_vaccinations,
	sum(cast(vax.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from Portfolio.dbo.CovidDeaths dea
join Portfolio.dbo.CovidVax vax
	on dea.location = vax.location
	and dea.date = vax.date
where dea.continent is not null
order by 2,3

--USE CTE

with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as (
Select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vax.new_vaccinations,
	sum(cast(vax.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from Portfolio.dbo.CovidDeaths dea
join Portfolio.dbo.CovidVax vax
	on dea.location = vax.location
	and dea.date = vax.date
where dea.continent is not null
--order by 2,3
)
select*,
	(RollingPeopleVaccinated/population)*100
from PopvsVac

-- OR can use TEMP TABLE

drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeoplevaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vax.new_vaccinations,
	sum(cast(vax.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from Portfolio.dbo.CovidDeaths dea
join Portfolio.dbo.CovidVax vax
	on dea.location = vax.location
	and dea.date = vax.date
where dea.continent is not null
--order by 2,3

select*,
	(RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated

-- creating view to store data for later visualizations

Create view PercentPopulationVaccinated as
Select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vax.new_vaccinations,
	sum(cast(vax.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from Portfolio.dbo.CovidDeaths dea
join Portfolio.dbo.CovidVax vax
	on dea.location = vax.location
	and dea.date = vax.date
where dea.continent is not null
--order by 2,3

Select*
from PercentPopulationVaccinated