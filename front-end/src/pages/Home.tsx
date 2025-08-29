import React, { Fragment, useEffect, useState } from 'react';
import "../Style/home.css";
import "bootstrap/dist/css/bootstrap.min.css";
import Card from "../component/card";

interface Product {
  _id: { $oid: string } | string;
  name: string;
  price: number;
  description: string;
  category: string;
  image: string;
}

function Home() {
  const [data, setData] = useState<Product[]>([]);
  const [selectedOption, setSelectedOption] = useState("idle");
  const [searchKeyword, setSearchKeyword] = useState("");
  const [filteredData, setFilteredData] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const response = await fetch(`${import.meta.env.VITE_PRODUCT_SERVICE_URL || 'http://localhost:9000'}/products`, {
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (response.ok) {
        const jsonData = await response.json();
        console.log("Fetched products:", jsonData); // Debug log
        setData(jsonData);
        setFilteredData([]); // Clear filtered data when fetching all
      } else {
        console.log("Failed to fetch products");
        setError("Failed to fetch products");
      }
    } catch (error) {
      console.error("Error:", error);
      setError("Error fetching products");
    } finally {
      setLoading(false);
    }
  };

  const handleLinkClick = (productID: string) => {
    localStorage.setItem("productID", productID);
    window.location.href = `/productinfo/${productID}`;
  };

  const handleSelectChange = async (event: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedCategory = event.target.value;
    setSelectedOption(selectedCategory);
    
    if (selectedCategory === "idle") {
      fetchData();
    } else {
      try {
        setLoading(true);
        const response = await fetch(`${import.meta.env.VITE_PRODUCT_SERVICE_URL || 'http://localhost:9000'}/filter/category/${selectedCategory}`, {
          method: "GET",
          headers: {
            "Content-Type": "application/json",
          },
        });
        
        if (response.ok) {
          const responseData = await response.json();
          console.log("Filtered products:", responseData); // Debug log
          // Handle both possible response structures
          const products = responseData.filteredProducts || responseData;
          setData(products);
          setFilteredData([]); // Clear filtered data
        } else {
          throw new Error("Failed to retrieve filtered data from server");
        }
      } catch (error) {
        console.error("Error:", error);
        setError("Error filtering products");
      } finally {
        setLoading(false);
      }
    }
  };

  const handleSearch = () => {
    if (!searchKeyword.trim()) {
      setFilteredData([]);
      return;
    }
    
    const filteredResults = data.filter((product: Product) =>
      product.name.toLowerCase().includes(searchKeyword.toLowerCase())
    );
    setFilteredData(filteredResults);
  };

  // Helper function to get product ID consistently
  const getProductId = (product: Product): string => {
    if (typeof product._id === 'string') {
      return product._id;
    } else if (product._id && typeof product._id === 'object' && '$oid' in product._id) {
      return product._id.$oid;
    }
    return '';
  };

  // Get the data to display (filtered or all)
  const displayData = filteredData.length > 0 ? filteredData : data;

  if (loading) {
    return (
      <div className="wid">
        <div className="container">
          <div className="row">
            <div className="col-lg-12 text-center">
              <h3>Loading products...</h3>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="wid">
        <div className="container">
          <div className="row">
            <div className="col-lg-12 text-center">
              <h3>Error: {error}</h3>
              <button onClick={fetchData} className="btn btn-primary">Retry</button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <Fragment>
      <div className="wid">
        <div className="container">
          <div className="row">
            <div className="col-lg-12">
              <div className="page-content">
                <div className="most-popular">
                  <div className="row">
                    <div className="col-lg-12">
                      <div className="heading-section inline">
                        <h4>
                          <em>Browse</em> Right Now
                        </h4>
                        <div className="selct">
                          <select
                            value={selectedOption}
                            onChange={handleSelectChange}
                          >
                            <option value="idle">ALL</option>
                            <option value="Action">Action</option>
                            <option value="Adventure">Adventure</option>
                            <option value="Casual">Casual</option>
                            <option value="Horror">Horror</option>
                            <option value="Open World">Open World</option>
                            <option value="Survival">Survival</option>
                            <option value="Simulation">Simulation</option>
                            <option value="Shooter">Shooter</option>
                          </select>
                          <span className="margleft"><i className="fa fa-search"></i></span>
                          
                          <input
                            className="newSearch"
                            type="text"
                            id="searchText"
                            name="searchKeyword"
                            placeholder="Search"
                            value={searchKeyword}
                            onChange={(e) => setSearchKeyword(e.target.value)}
                          />
                          <button className="searchButton" onClick={handleSearch}>Search</button>

                        </div>
                      </div>
                      
                      {displayData.length === 0 ? (
                        <div className="row">
                          <div className="col-lg-12 text-center">
                            <h3>No products found</h3>
                          </div>
                        </div>
                      ) : (
                        <div className="row">
                          {displayData.map((product: Product) => {
                            const productId = getProductId(product);
                            if (!productId) {
                              console.warn("Product missing ID:", product);
                              return null;
                            }
                            
                            return (
                              <div
                                className="col-lg-3 col-sm-6"
                                onClick={() => handleLinkClick(productId)}
                                style={{ cursor: "pointer" }}
                                key={productId}
                              >
                                <Card
                                  name={product.name}
                                  price={product.price}
                                  imgsrc={product.image}
                                  category={product.category}
                                />
                              </div>
                            );
                          })}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Fragment>
  );
}

export default Home;
