import fs from "fs/promises";
import sharp from "sharp";

const cities: City[] = [
  {
    name: "everett",
    title: "Everett",
  },
  {
    name: "arlington",
    title: "Arlington",
  },
  {
    name: "cambridge",
    title: "Cambridge",
  },
  {
    name: "chelsea",
    title: "Chelsea",
  },
  {
    name: "lexington",
    title: "Lexington",
  },
  {
    name: "melrose",
    title: "Melrose",
  },
  {
    name: "reading",
    title: "Reading",
  },
  {
    name: "somerville",
    title: "Somerville",
  },
  {
    name: "watertown",
    title: "Watertown",
  },
  {
    name: "winchester",
    title: "Winchester",
  },
  {
    name: "woburn",
    title: "Woburn",
  },
  {
    name: "burlington",
    title: "Burlington",
  },
  {
    name: "revere",
    title: "Revere",
  },
  {
    name: "medford",
    title: "Medford",
  },
]
type City = { name: string; title: string }

const logoPaths = {
  city: (name: string) => `app/assets/images/logos/${name}-city.png`,
  mrwa: "app/assets/images/logos/mrwa-logo.png",
  base: "app/assets/images/logos/base-adopt-a-drain.svg",
  site: (city: string) => `app/assets/images/logos/adopt-a-drain-${city}.png`,
}

const geometry = {
  width: 600,
  height: 400,
  logoY: 290,
  logo1X: 150,
  logo2X: 450,
}

const resizeLogo = async (logo: string) => {
  const img = sharp(logo).resize(200, 200, { fit: "inside" })
  const data = await img.toBuffer()
  const { width, height } = await sharp(data).metadata()
  return { width: width!, height: height!, data }
}
type Logo = Awaited<ReturnType<typeof resizeLogo>>

const centeredAt = ({
  logo,
  left,
  top,
}: {
  logo: Logo
  left: number
  top: number
}) => ({
  input: logo.data,
  top: Math.round(top - logo.height * 0.5),
  left: Math.round(left - logo.width * 0.5),
})

export async function generateLogos() {
  const base = await fs.readFile(logoPaths.base)
  const mrwaLogo = await resizeLogo(logoPaths.mrwa)

  for (const city of cities) {
    await generateLogo(city)
  }

  async function generateLogo(city: City) {
    const cityLogo = await resizeLogo(logoPaths.city(city.name))
    const baseLogo = baseWithTitle(city.title)
    await sharp(baseLogo)
      .resize(geometry.width, geometry.height)
      .composite([
        centeredAt({
          logo: cityLogo,
          top: geometry.logoY,
          left: geometry.logo1X,
        }),
        centeredAt({
          logo: mrwaLogo,
          top: geometry.logoY,
          left: geometry.logo2X,
        }),
      ])
      .flatten({ background: "#ffffff" })
      .toFile(logoPaths.site(city.name))
  }

  function baseWithTitle(city: string) {
    return Buffer.from(base.toString().replace("PLACEHOLDER", city))
  }
}

generateLogos()
  .then(() => console.log("done"))
  .catch(e => {
    console.error("Error generating logos:", e.message)
    process.exitCode = 1
  })
