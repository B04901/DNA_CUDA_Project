from urllib.request import urlopen

url = (
    "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
    "?db=nuccore&id=NC_000001.11&rettype=fasta&retmode=text"
)

output_file = "chr1.fa"

print("Downloading human chromosome 1 from NCBI...")

with urlopen(url, timeout=120) as response:
    data = response.read()

with open(output_file, "wb") as file:
    file.write(data)

print("Download complete:", output_file)