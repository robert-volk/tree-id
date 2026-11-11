import Foundation

struct TreeFact {
    let type: String    // Hardwood / Conifer
    let size: String
    let note: String
}

/// Genus-level notes shown under an ID result. Looked up by the first word of the scientific name.
enum TreeFacts {
    static func lookup(scientific: String) -> TreeFact? {
        guard let genus = scientific.split(separator: " ").first else { return nil }
        return table[String(genus).lowercased()]
    }

    private static let table: [String: TreeFact] = [
        "acer": TreeFact(type: "Hardwood", size: "30 to 100 ft", note: "Maples have paired, opposite leaves and winged seeds. Many turn brilliant red or orange in fall."),
        "quercus": TreeFact(type: "Hardwood", size: "40 to 100 ft", note: "Oaks bear acorns. White oaks have rounded leaf lobes, red oaks have bristle-tipped lobes."),
        "betula": TreeFact(type: "Hardwood", size: "40 to 70 ft", note: "Birches have thin, peeling bark and small toothed leaves. Often the first trees to colonize cleared land."),
        "pinus": TreeFact(type: "Conifer", size: "40 to 150 ft", note: "Pines carry needles in bundles of 2, 3, or 5. Count the bundle to narrow the species."),
        "picea": TreeFact(type: "Conifer", size: "40 to 130 ft", note: "Spruces have sharp, four-sided needles attached singly to the twig."),
        "abies": TreeFact(type: "Conifer", size: "40 to 150 ft", note: "Firs have flat, soft needles and upright cones. Needles leave a round scar."),
        "tsuga": TreeFact(type: "Conifer", size: "50 to 100 ft", note: "Hemlocks have short, flat needles with two pale stripes underneath and tiny hanging cones."),
        "pseudotsuga": TreeFact(type: "Conifer", size: "80 to 250 ft", note: "Douglas-fir cones have three-pointed bracts poking out between the scales."),
        "thuja": TreeFact(type: "Conifer", size: "30 to 200 ft", note: "Arborvitae and redcedars have flat sprays of scale-like leaves."),
        "juniperus": TreeFact(type: "Conifer", size: "10 to 60 ft", note: "Junipers have scale or needle leaves and blue, berry-like cones."),
        "cedrus": TreeFact(type: "Conifer", size: "40 to 100 ft", note: "True cedars carry needles in tufts on short spur shoots."),
        "sequoia": TreeFact(type: "Conifer", size: "200 to 380 ft", note: "Coast redwoods are the tallest trees on Earth, with thick, spongy red bark."),
        "larix": TreeFact(type: "Conifer", size: "50 to 100 ft", note: "Larches are conifers that drop their needles each fall."),
        "taxus": TreeFact(type: "Conifer", size: "15 to 60 ft", note: "Yews have flat dark needles and red, fleshy arils. Seeds and foliage are poisonous."),
        "fagus": TreeFact(type: "Hardwood", size: "50 to 100 ft", note: "Beeches have smooth gray bark that keeps carved initials for decades."),
        "fraxinus": TreeFact(type: "Hardwood", size: "50 to 80 ft", note: "Ashes have opposite, compound leaves. Emerald ash borer has killed many across North America."),
        "ulmus": TreeFact(type: "Hardwood", size: "60 to 100 ft", note: "Elms have lopsided leaf bases and double-toothed edges."),
        "populus": TreeFact(type: "Hardwood", size: "40 to 100 ft", note: "Poplars and aspens have flattened leaf stalks, so the leaves flutter in a breeze."),
        "salix": TreeFact(type: "Hardwood", size: "15 to 80 ft", note: "Willows have slender leaves and love wet ground."),
        "tilia": TreeFact(type: "Hardwood", size: "50 to 80 ft", note: "Lindens and basswoods have heart-shaped leaves and fragrant summer flowers."),
        "juglans": TreeFact(type: "Hardwood", size: "50 to 100 ft", note: "Walnuts have long compound leaves and round nuts in green husks."),
        "carya": TreeFact(type: "Hardwood", size: "60 to 100 ft", note: "Hickories have compound leaves and tough, edible nuts. Their wood is very hard."),
        "platanus": TreeFact(type: "Hardwood", size: "70 to 100 ft", note: "Sycamores have mottled, peeling bark and large maple-like leaves."),
        "liquidambar": TreeFact(type: "Hardwood", size: "60 to 100 ft", note: "Sweetgum has star-shaped leaves and spiky seed balls."),
        "prunus": TreeFact(type: "Hardwood", size: "15 to 60 ft", note: "Cherries and plums have horizontal bark lines and spring blossoms."),
        "malus": TreeFact(type: "Hardwood", size: "15 to 30 ft", note: "Apples and crabapples bloom in spring and carry small pomes in fall."),
        "cornus": TreeFact(type: "Hardwood", size: "15 to 30 ft", note: "Dogwoods have leaf veins that curve toward the tip and showy spring bracts."),
        "magnolia": TreeFact(type: "Hardwood", size: "20 to 80 ft", note: "Magnolias have large, simple leaves and big, ancient-looking flowers."),
        "ginkgo": TreeFact(type: "Hardwood", size: "50 to 80 ft", note: "Ginkgo has fan-shaped leaves and is a living fossil, nearly unchanged for 200 million years."),
        "robinia": TreeFact(type: "Hardwood", size: "40 to 70 ft", note: "Black locust has compound leaves, paired thorns, and deeply furrowed bark."),
        "gleditsia": TreeFact(type: "Hardwood", size: "50 to 80 ft", note: "Honey locust has long seed pods and, often, large branched thorns."),
        "aesculus": TreeFact(type: "Hardwood", size: "30 to 80 ft", note: "Buckeyes and horse chestnuts have palm-shaped compound leaves and shiny brown nuts."),
        "castanea": TreeFact(type: "Hardwood", size: "40 to 100 ft", note: "Chestnuts have long, toothed leaves and spiny burs around the nuts."),
        "carpinus": TreeFact(type: "Hardwood", size: "20 to 40 ft", note: "Hornbeams have smooth, muscle-like trunks and toothed leaves."),
        "alnus": TreeFact(type: "Hardwood", size: "30 to 70 ft", note: "Alders grow near water and carry small woody, cone-like catkins."),
        "catalpa": TreeFact(type: "Hardwood", size: "30 to 60 ft", note: "Catalpas have huge heart-shaped leaves and long bean-like pods."),
        "celtis": TreeFact(type: "Hardwood", size: "40 to 80 ft", note: "Hackberries have warty bark and small, dark berries."),
        "liriodendron": TreeFact(type: "Hardwood", size: "70 to 120 ft", note: "Tulip trees have four-lobed, squared-off leaves and tulip-shaped flowers."),
        "ilex": TreeFact(type: "Hardwood", size: "10 to 50 ft", note: "Hollies have glossy leaves and bright berries on female trees."),
    ]
}
